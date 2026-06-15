require "json"
require "rbconfig"

require_relative "../lib/fast_excel"

module FastExcel
  module Benchmarks
    module StringEscaping
      XML_SPECIAL_PATTERN = /[&<>]|[\u0000-\u0008\u000B\u000C\u000E-\u001F]/.freeze

      module_function

      def native_escape(string)
        Libxlsxwriter.escape_data(Libxlsxwriter.escape_control_characters(string))
      end

      def scan_then_native_escape(string)
        return string unless needs_native_escape?(string)

        native_escape(string)
      end

      def needs_native_escape?(string)
        XML_SPECIAL_PATTERN.match?(string)
      end
    end

    class StringEscapingProfile
      Result = Struct.new(:strings, :iterations, :profiles, :writer_path, :platform, keyword_init: true) do
        def to_h
          {
            strings: strings,
            iterations: iterations,
            profiles: profiles,
            writer_path: writer_path,
            platform: platform
          }
        end
      end

      DATASETS = {
        ascii: "ordinary commodity description without xml characters",
        utf8: "商品分類 ordinary UTF-8 description",
        xml_special: "prepared foods & cereals <review> > threshold",
        controls: "prepared\u0001foods\u0002control"
      }.freeze

      def initialize(strings: 10_000, iterations: 3)
        @strings = strings
        @iterations = iterations
      end

      def run
        Result.new(
          strings: strings,
          iterations: iterations,
          profiles: DATASETS.transform_values { |sample| profile_dataset(sample) },
          writer_path: "WorksheetValueWriter#write_cell -> Worksheet#write_string -> FFI :string -> libxlsxwriter worksheet_write_string; XML escaping happens in libxlsxwriter for normal workbook writes.",
          platform: platform_metadata
        )
      end

      private

      attr_reader :strings, :iterations

      def profile_dataset(sample)
        values = Array.new(strings) { |index| "#{sample} #{index}" }

        {
          native_escape: measure(values) { |value| StringEscaping.native_escape(value) },
          scan_then_native_escape: measure(values) { |value| StringEscaping.scan_then_native_escape(value) },
          workbook_write: measure_workbook(values)
        }
      end

      def measure(values)
        GC.start
        before_gc = GC.stat
        started_at = monotonic_time

        iterations.times do
          values.each { |value| yield(value) }
        end

        finished_at = monotonic_time
        after_gc = GC.stat

        profile_hash(values.length * iterations, finished_at - started_at, before_gc, after_gc)
      end

      def measure_workbook(values)
        GC.start
        before_gc = GC.stat
        started_at = monotonic_time

        iterations.times do
          workbook = FastExcel.open(constant_memory: true)
          worksheet = workbook.add_worksheet("Strings")

          values.each_with_index do |value, row_number|
            worksheet.write_value(row_number, 0, value)
          end

          workbook.read_string
        end

        finished_at = monotonic_time
        after_gc = GC.stat

        profile_hash(values.length * iterations, finished_at - started_at, before_gc, after_gc)
      end

      def profile_hash(total_strings, seconds, before_gc, after_gc)
        {
          seconds: seconds,
          strings_per_second: (total_strings / seconds).round(2),
          allocated_objects: after_gc.fetch(:total_allocated_objects) - before_gc.fetch(:total_allocated_objects),
          heap_live_slots_delta: after_gc.fetch(:heap_live_slots) - before_gc.fetch(:heap_live_slots)
        }
      end

      def platform_metadata
        {
          ruby_version: RUBY_VERSION,
          ruby_platform: RUBY_PLATFORM,
          host_cpu: RbConfig::CONFIG["host_cpu"],
          host_os: RbConfig::CONFIG["host_os"],
          yjit: defined?(RubyVM::YJIT) ? RubyVM::YJIT.enabled? : false
        }
      end

      def monotonic_time
        Process.clock_gettime(Process::CLOCK_MONOTONIC)
      end
    end
  end
end

if $PROGRAM_NAME == __FILE__
  strings = Integer(ENV.fetch("STRING_ESCAPE_PROFILE_STRINGS", "10000"))
  iterations = Integer(ENV.fetch("STRING_ESCAPE_PROFILE_ITERATIONS", "3"))
  result = FastExcel::Benchmarks::StringEscapingProfile.new(strings: strings, iterations: iterations).run
  puts JSON.pretty_generate(result.to_h)
end
