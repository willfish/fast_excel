require "json"
require "open3"
require "rbconfig"

require_relative "trade_tariff_report"

module FastExcel
  module Benchmarks
    class CompressionBackend
      def initialize(rows: 2_000)
        @rows = rows
      end

      def run
        report = TradeTariffReport.new(rows: rows).run
        library_path = native_library_path

        {
          rows: rows,
          native_library_path: library_path,
          linked_libraries: linked_libraries(library_path),
          benchmark: report.to_h
        }
      end

      private

      attr_reader :rows

      def native_library_path
        suffix = Libxlsxwriter::LIB_FILENAME
        [
          Gem.loaded_specs["uber_fast_excel"]&.extension_dir,
          Gem.loaded_specs["fast_excel"]&.extension_dir,
          File.expand_path("../lib", __dir__)
        ].compact.map { |directory| File.join(directory, suffix) }.find { |path| File.exist?(path) }
      end

      def linked_libraries(path)
        return [] unless path

        command = linked_library_command(path)
        return [] unless command

        stdout, stderr, status = Open3.capture3(*command)
        output = stdout.empty? ? stderr : stdout

        {
          command: command.join(" "),
          status: status.exitstatus,
          output: output.lines.map(&:chomp)
        }
      end

      def linked_library_command(path)
        host_os = RbConfig::CONFIG["host_os"]

        if host_os.include?("darwin")
          ["otool", "-L", path]
        elsif host_os.match?(/linux|bsd/)
          ["ldd", path]
        elsif host_os.match?(/mswin|mingw|cygwin/)
          nil
        end
      end
    end
  end
end

if $PROGRAM_NAME == __FILE__
  rows = Integer(ENV.fetch("TRADE_TARIFF_PERFORMANCE_ROWS", "2000"))
  result = FastExcel::Benchmarks::CompressionBackend.new(rows: rows).run
  puts JSON.pretty_generate(result)
end
