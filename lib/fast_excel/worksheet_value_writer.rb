module FastExcel
  class WorksheetValueWriter
    NO_WIDTH = Object.new.freeze

    def initialize(worksheet)
      @worksheet = worksheet
    end

    def write(row_number, cell_number, value, format = nil)
      write_cell(row_number, cell_number, value, format)
      add_auto_width(value, format, cell_number) if worksheet.auto_width?
    end

    private

    attr_reader :worksheet

    def write_cell(row_number, cell_number, value, format)
      if value.is_a?(Numeric)
        worksheet.write_number(row_number, cell_number, value, format)
      elsif value.is_a?(Time)
        worksheet.write_number(row_number, cell_number, FastExcel.date_num(value), format)
      elsif datetime_value?(value)
        worksheet.write_datetime(row_number, cell_number, FastExcel.lxw_datetime(value), format)
      elsif date_value?(value)
        worksheet.write_datetime(row_number, cell_number, FastExcel.lxw_date(value), format)
      elsif value.is_a?(TrueClass) || value.is_a?(FalseClass)
        worksheet.write_boolean(row_number, cell_number, value ? 1 : 0, format)
      elsif value.is_a?(FastExcel::Formula)
        worksheet.write_formula(row_number, cell_number, value.fml, format)
      elsif value.is_a?(FastExcel::URL)
        worksheet.write_url(row_number, cell_number, value.url, format)
      elsif value.is_a?(FastExcel::RichString)
        Libxlsxwriter::WorksheetPointerBuilders.with_rich_string(value) do |rich_string|
          worksheet.write_rich_string(row_number, cell_number, rich_string, format)
        end
      else
        worksheet.write_string(row_number, cell_number, value.to_s, format)
      end
    end

    def add_auto_width(value, format, cell_number)
      text = auto_width_text(value)
      worksheet.add_text_width(text, format, cell_number) unless text.equal?(NO_WIDTH)
    end

    def auto_width_text(value)
      if value.is_a?(FastExcel::URL)
        value.url
      elsif value.is_a?(FastExcel::RichString)
        value.fragments.map { |fragment| fragment[:text] }.join
      elsif text_width_value?(value)
        value
      else
        NO_WIDTH
      end
    end

    def text_width_value?(value)
      return false if value.is_a?(Numeric)
      return false if date_value?(value)
      return false if value.is_a?(Time)
      return false if datetime_value?(value)
      return false if value.is_a?(TrueClass) || value.is_a?(FalseClass)
      return false if value.is_a?(FastExcel::Formula)

      true
    end

    def date_value?(value)
      defined?(Date) && value.is_a?(Date)
    end

    def datetime_value?(value)
      defined?(DateTime) && value.is_a?(DateTime)
    end
  end

  private_constant :WorksheetValueWriter
end
