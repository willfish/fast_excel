require "etc"
require "json"
require "rbconfig"
require "stringio"
require "zip"

require_relative "../lib/fast_excel"

module FastExcel
  module Benchmarks
    module SharedStringStrategy
      module_function

      def archive_profile(content)
        worksheet_xml = nil
        shared_strings_xml = nil
        compressed_bytes = 0
        uncompressed_bytes = 0

        Zip::File.open_buffer(StringIO.new(content)) do |zip|
          zip.each do |entry|
            compressed_bytes += entry.compressed_size
            uncompressed_bytes += entry.size

            case entry.name
            when "xl/worksheets/sheet1.xml"
              worksheet_xml = entry.get_input_stream.read
            when "xl/sharedStrings.xml"
              shared_strings_xml = entry.get_input_stream.read
            end
          end
        end

        {
          bytes: content.bytesize,
          zip_compressed_bytes: compressed_bytes,
          zip_uncompressed_bytes: uncompressed_bytes,
          shared_strings_xml: !shared_strings_xml.nil?,
          shared_string_items: shared_strings_xml ? shared_strings_xml.scan("<si>").length : 0,
          inline_string_cells: worksheet_xml ? worksheet_xml.scan('t="inlineStr"').length : 0
        }
      end

      class Profile
        STRATEGIES = {
          constant_memory_inline_strings: true,
          normal_memory_shared_strings: false
        }.freeze

        Result = Struct.new(:rows, :columns, :datasets, :recommendation, :platform, keyword_init: true) do
          def to_h
            {
              rows: rows,
              columns: columns,
              datasets: datasets,
              recommendation: recommendation,
              platform: platform
            }
          end
        end

        def initialize(rows: 5_000, columns: 6)
          @rows = rows
          @columns = columns
        end

        def run
          Result.new(
            rows: rows,
            columns: columns,
            datasets: {
              repeated: profile_dataset(method(:repeated_value)),
              unique: profile_dataset(method(:unique_value)),
              mixed: profile_dataset(method(:mixed_value))
            },
            recommendation: recommendation,
            platform: platform_metadata
          )
        end

        private

        attr_reader :rows, :columns

        def profile_dataset(value_builder)
          STRATEGIES.transform_values do |constant_memory|
            measure(constant_memory: constant_memory, value_builder: value_builder)
          end
        end

        def measure(constant_memory:, value_builder:)
          GC.start
          before_gc = GC.stat
          before_rss = rss_bytes
          started_at = monotonic_time

          content = build_workbook(constant_memory: constant_memory, value_builder: value_builder)

          finished_at = monotonic_time
          after_rss = rss_bytes
          after_gc = GC.stat

          SharedStringStrategy.archive_profile(content).merge(
            seconds: finished_at - started_at,
            allocated_objects: after_gc.fetch(:total_allocated_objects) - before_gc.fetch(:total_allocated_objects),
            heap_live_slots_delta: after_gc.fetch(:heap_live_slots) - before_gc.fetch(:heap_live_slots),
            rss_bytes_delta: rss_delta(before_rss, after_rss)
          )
        end

        def build_workbook(constant_memory:, value_builder:)
          workbook = FastExcel.open(constant_memory: constant_memory)
          worksheet = workbook.add_worksheet("Strings")

          rows.times do |row_number|
            values = Array.new(columns) do |column_number|
              value_builder.call(row_number, column_number)
            end

            worksheet.write_row(row_number, values)
          end

          workbook.read_string
        end

        def repeated_value(row_number, column_number)
          ["Active", "Declarable", "Suspended", "Import control"][((row_number + column_number) % 4)]
        end

        def unique_value(row_number, column_number)
          "commodity-#{row_number}-#{column_number}-#{format('%010d', 1_000_000_000 + row_number)}"
        end

        def mixed_value(row_number, column_number)
          case column_number % 6
          when 0
            format("%010d", 1_000_000_000 + row_number)
          when 1
            "Prepared food product #{row_number} with seasonal classification"
          when 2
            repeated_value(row_number, column_number)
          when 3
            "Third country duty"
          when 4
            "https://www.trade-tariff.service.gov.uk/commodities/#{format('%010d', 1_000_000_000 + row_number)}"
          else
            row_number % 25 == 0 ? "Review rules of origin" : "Routine measure"
          end
        end

        def recommendation
          [
            "Use constant_memory: true for large Rails exports when memory bounds matter; libxlsxwriter stores those strings inline.",
            "Use normal memory mode only for smaller repeated-string workbooks where the shared string table size and memory growth are acceptable.",
            "Do not make the strategy adaptive without an opt-in API because switching away from constant memory changes the memory guarantee."
          ]
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

        def rss_bytes
          return nil unless File.exist?("/proc/self/statm")

          pages = File.read("/proc/self/statm").split.fetch(1).to_i
          pages * Etc.sysconf(Etc::SC_PAGE_SIZE)
        rescue StandardError
          nil
        end

        def rss_delta(before_rss, after_rss)
          return nil if before_rss.nil? || after_rss.nil?

          after_rss - before_rss
        end

        def monotonic_time
          Process.clock_gettime(Process::CLOCK_MONOTONIC)
        end
      end
    end
  end
end

if $PROGRAM_NAME == __FILE__
  rows = Integer(ENV.fetch("SHARED_STRING_PROFILE_ROWS", "5000"))
  columns = Integer(ENV.fetch("SHARED_STRING_PROFILE_COLUMNS", "6"))
  result = FastExcel::Benchmarks::SharedStringStrategy::Profile.new(rows: rows, columns: columns).run
  puts JSON.pretty_generate(result.to_h)
end
