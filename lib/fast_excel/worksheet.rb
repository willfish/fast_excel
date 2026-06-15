module FastExcel
  module WorksheetExt
    attr_accessor :workbook

    include AttributeHelper

    def initialize(struct)
      @is_open = true
      @col_formats = {}
      @last_row_number = -1
      super(struct)
    end

    def write_row(row_number, values, formats = nil)
      values.each_with_index do |value, index|
        format = if formats
          formats.is_a?(Array) ? formats[index] : formats
        end

        write_value(row_number, index, value, format)
      end
    end

    def auto_width?
      defined?(@auto_width) && @auto_width
    end

    def auto_width=(v)
      @auto_width = v
      @column_widths = {}
    end

    def calculated_column_widths
      @column_widths || {}
    end

    def write_value(row_number, cell_number, value, format = nil)

      if workbook.constant_memory? && row_number < @last_row_number
        raise ArgumentError, "Can not write to saved row in constant_memory mode (attempted row: #{row_number}, last saved row: #{last_row_number})"
      end

      value_writer.write(row_number, cell_number, value, format)

      @last_row_number = row_number > @last_row_number ? row_number : @last_row_number
    end

    def add_text_width(value, format, cell_number)
      font_size = 0
      if format
        font_size = format.font_size
      end

      if font_size == 0
        if @col_formats[cell_number] && @col_formats[cell_number].font_size
          font_size = @col_formats[cell_number].font_size
        end
      end

      if font_size == 0
        font_size = workbook.default_format.font_size
      end

      font_size = 13 if font_size == nil || font_size == 0

      scale = 0.08
      new_width = (scale * font_size * value.to_s.length )
      @column_widths[cell_number] = if new_width > (@column_widths[cell_number] || 0)
        new_width
      else
        @column_widths[cell_number]
      end
    end

    def append_row(values, formats = nil)
      @last_row_number += 1
      write_row(last_row_number, values, formats)
    end

    def <<(values)
      append_row(values)
    end

    def set_h_pagebreaks(breaks)
      Libxlsxwriter::WorksheetPointerBuilders.with_horizontal_pagebreaks(breaks) do |pointer|
        Libxlsxwriter.worksheet_set_h_pagebreaks(self, pointer)
      end
    end

    def set_v_pagebreaks(breaks)
      Libxlsxwriter::WorksheetPointerBuilders.with_vertical_pagebreaks(breaks) do |pointer|
        Libxlsxwriter.worksheet_set_v_pagebreaks(self, pointer)
      end
    end

    def last_row_number
      @last_row_number
    end

    def value_writer
      @value_writer ||= WorksheetValueWriter.new(self)
    end
    private :value_writer

    def set_column(start_col, end_col, width = nil, format = nil)
      super(start_col, end_col, width || DEF_COL_WIDTH, format)

      return unless format
      start_col.upto(end_col) do |i|
        @col_formats[i] = format
      end
    end

    def set_column_width(col, width)
      set_column(col, col, width, @col_formats[col])
    end

    def set_columns_width(start_col, end_col, width)
      start_col.upto(end_col) do |i|
        set_column_width(i, width)
      end
    end

    def enable_filters!(start_col: 0, end_col:)
      autofilter(0, start_col, @last_row_number, end_col)
    end

    def close
      if auto_width?
        @column_widths.transform_values!{ |width| width || DEF_COL_WIDTH }.each do |num, width|
          set_column_width(num, width + 0.2)
        end
      end
    end
  end
end
