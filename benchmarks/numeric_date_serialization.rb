require "date"
require "json"
require "rbconfig"

require_relative "../lib/fast_excel"

module FastExcel
  module Benchmarks
    class NumericDateSerialization
      Result = Struct.new(
        :rows,
        :columns,
        :write_profiles,
        :conversion_profiles,
        :writer_paths,
        :interpretation,
        :platform,
        keyword_init: true
      ) do
        def to_h
          {
            rows: rows,
            columns: columns,
            write_profiles: write_profiles,
            conversion_profiles: conversion_profiles,
            writer_paths: writer_paths,
            interpretation: interpretation,
            platform: platform
          }
        end
      end

      def initialize(rows: 5_000, columns: 8, constant_memory: true)
        @rows = rows
        @columns = columns
        @constant_memory = constant_memory
      end

      def run
        Result.new(
          rows: rows,
          columns: columns,
          write_profiles: {
            integers: measure_write { |index| index },
            floats: measure_write { |index| index + 0.123456789 },
            times: measure_write { |index| Time.utc(2026, 1, 1) + index },
            dates: measure_write { |index| Date.new(2026, 1, 1) + index },
            datetimes: measure_write { |index| DateTime.new(2026, 1, 1, 12, 30, 15) + Rational(index, 86_400) }
          },
          conversion_profiles: {
            time_date_num: measure_conversion { |index| FastExcel.date_num(Time.utc(2026, 1, 1) + index) },
            date_lxw_datetime: measure_conversion { |index| FastExcel.lxw_datetime(Date.new(2026, 1, 1).next_day(index).to_datetime) },
            datetime_lxw_datetime: measure_conversion { |index| FastExcel.lxw_datetime(DateTime.new(2026, 1, 1, 12, 30, 15) + Rational(index, 86_400)) }
          },
          writer_paths: writer_paths,
          interpretation: interpretation,
          platform: platform_metadata
        )
      end

      private

      attr_reader :rows, :columns, :constant_memory

      def measure_write
        GC.start
        before_gc = GC.stat
        started_at = monotonic_time

        workbook = FastExcel.open(constant_memory: constant_memory)
        worksheet = workbook.add_worksheet("Profile")

        rows.times do |row_number|
          values = Array.new(columns) { |column_number| yield(row_number + column_number) }
          worksheet.write_row(row_number, values)
        end

        content = workbook.read_string
        finished_at = monotonic_time
        after_gc = GC.stat

        profile_hash(finished_at - started_at, before_gc, after_gc).merge(bytes: content.bytesize)
      end

      def measure_conversion
        iterations = rows * columns

        GC.start
        before_gc = GC.stat
        started_at = monotonic_time

        iterations.times do |index|
          yield(index)
        end

        finished_at = monotonic_time
        after_gc = GC.stat

        profile_hash(finished_at - started_at, before_gc, after_gc)
      end

      def profile_hash(seconds, before_gc, after_gc)
        {
          seconds: seconds,
          cells_per_second: ((rows * columns) / seconds).round(2),
          allocated_objects: after_gc.fetch(:total_allocated_objects) - before_gc.fetch(:total_allocated_objects),
          heap_live_slots_delta: after_gc.fetch(:heap_live_slots) - before_gc.fetch(:heap_live_slots)
        }
      end

      def writer_paths
        {
          integers: "WorksheetValueWriter#write_cell -> Worksheet#write_number -> FFI :double -> libxlsxwriter worksheet_write_number",
          floats: "WorksheetValueWriter#write_cell -> Worksheet#write_number -> FFI :double -> libxlsxwriter worksheet_write_number",
          times: "FastExcel.date_num in Ruby -> Worksheet#write_number -> FFI :double -> libxlsxwriter worksheet_write_number",
          dates: "FastExcel.lxw_datetime in Ruby -> Worksheet#write_datetime -> FFI Datetime struct -> libxlsxwriter worksheet_write_datetime",
          datetimes: "FastExcel.lxw_datetime in Ruby -> Worksheet#write_datetime -> FFI Datetime struct -> libxlsxwriter worksheet_write_datetime"
        }
      end

      def interpretation
        [
          "Ruby classifies values and converts Time values to Excel serial doubles before crossing FFI.",
          "Date and DateTime values cross FFI as libxlsxwriter datetime structs.",
          "The decimal/XML text formatting for numeric cell values is owned by libxlsxwriter after the FFI call.",
          "Use the conversion_profiles numbers to decide whether Ruby-side date conversion is worth optimizing before considering Ryū or Dragonbox-style decimal formatting work."
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

      def monotonic_time
        Process.clock_gettime(Process::CLOCK_MONOTONIC)
      end
    end
  end
end

if $PROGRAM_NAME == __FILE__
  rows = Integer(ENV.fetch("NUMERIC_DATE_PROFILE_ROWS", "5000"))
  columns = Integer(ENV.fetch("NUMERIC_DATE_PROFILE_COLUMNS", "8"))
  result = FastExcel::Benchmarks::NumericDateSerialization.new(rows: rows, columns: columns).run
  puts JSON.pretty_generate(result.to_h)
end
