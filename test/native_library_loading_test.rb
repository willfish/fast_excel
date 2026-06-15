require_relative "test_helper"
require "json"
require "open3"
require "rbconfig"

class NativeLibraryLoadingTest < Minitest::Test
  def test_native_library_candidates_include_renamed_gem_extension_path
    source_tree_library = File.expand_path("../lib/libxlsxwriter.#{library_suffix}", __dir__)
    uber_extension_library = "/tmp/uber-fast-excel/extensions/libxlsxwriter.#{library_suffix}"
    fast_excel_extension_library = "/tmp/fast-excel/extensions/libxlsxwriter.#{library_suffix}"

    assert_equal [
      uber_extension_library,
      fast_excel_extension_library,
      source_tree_library
    ], captured_library_candidates(
      "uber_fast_excel" => File.dirname(uber_extension_library),
      "fast_excel" => File.dirname(fast_excel_extension_library)
    )
  end

  private

  def captured_library_candidates(spec_extension_dirs)
    specs = spec_extension_dirs.transform_values { |extension_dir| { "extension_dir" => extension_dir } }
    script = <<~RUBY
      require "ffi"
      require "json"

      Spec = Struct.new(:extension_dir)
      JSON.parse(#{JSON.generate(specs).dump}).each do |name, attributes|
        Gem.loaded_specs[name] = Spec.new(attributes.fetch("extension_dir"))
      end

      module FFI
        module Library
          class CapturedLibraries < StandardError
            attr_reader :libraries

            def initialize(libraries)
              @libraries = libraries
              super("captured libraries")
            end
          end

          def ffi_lib(*libraries)
            raise CapturedLibraries.new(libraries.flatten)
          end
        end
      end

      begin
        load #{File.expand_path("../lib/fast_excel/binding.rb", __dir__).dump}
      rescue FFI::Library::CapturedLibraries => error
        puts JSON.generate(error.libraries)
      end
    RUBY

    stdout, stderr, status = Open3.capture3(RbConfig.ruby, "-e", script)
    assert status.success?, stderr

    JSON.parse(stdout)
  end

  def library_suffix
    require "ffi"
    FFI::Platform::LIBSUFFIX
  end
end
