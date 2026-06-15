module Libxlsxwriter
  module WorksheetPointerBuilders
    module_function

    def with_table_options(options)
      strings = []
      columns = Array(options[:columns]).map do |header|
        TableColumn.new.tap do |column|
          strings << FFI::MemoryPointer.from_string(header.to_s)
          column[:header] = strings.last
          column[:formula] = FFI::Pointer::NULL
          column[:total_string] = FFI::Pointer::NULL
          column[:header_format] = FFI::Pointer::NULL
          column[:format] = FFI::Pointer::NULL
        end
      end

      columns_pointer = FFI::Pointer::NULL
      unless columns.empty?
        columns_pointer = FFI::MemoryPointer.new(:pointer, columns.length + 1)
        columns_pointer.write_array_of_pointer(columns.map(&:to_ptr) + [FFI::Pointer::NULL])
      end

      yield TableOptions.build(options, columns_pointer)
    end

    def with_rich_string(value)
      strings = []
      tuples = value.fragments.map do |fragment|
        RichStringTuple.new.tap do |tuple|
          strings << FFI::MemoryPointer.from_string(fragment[:text])
          tuple[:format] = fragment[:format]&.to_ptr || FFI::Pointer::NULL
          tuple[:string] = strings.last
        end
      end

      FFI::MemoryPointer.new(:pointer, tuples.length + 1).tap do |pointer|
        pointer.write_array_of_pointer(tuples.map(&:to_ptr) + [FFI::Pointer::NULL])
        yield pointer
      end
    end

    def with_horizontal_pagebreaks(breaks, &block)
      with_pagebreaks(breaks, :uint32, :write_array_of_uint32, &block)
    end

    def with_vertical_pagebreaks(breaks, &block)
      with_pagebreaks(breaks, :uint16, :write_array_of_uint16, &block)
    end

    def with_pagebreaks(breaks, pointer_type, writer)
      return yield breaks if breaks.is_a?(FFI::Pointer)

      breakpoints = breaks.to_a
      breakpoints << 0 unless breakpoints.last == 0

      FFI::MemoryPointer.new(pointer_type, breakpoints.size) do |pointer|
        pointer.public_send(writer, breakpoints)
        yield pointer
      end
    end
    private_class_method :with_pagebreaks
  end
end
