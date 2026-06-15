require 'fileutils'
require 'set'

module FastExcel
  ERROR_ENUM = Libxlsxwriter.enum_type(:error)

  def self.open(filename = nil, constant_memory: false, default_format: nil)
    tmp_file = false
    if filename
      if File.exist?(filename) && File.size(filename) > 0
        raise ArgumentError, "File '#{filename}' already exists. FastExcel can not open existing files, only create new files"
      end
    else
      require 'tmpdir'
      filename = "#{Dir.mktmpdir}/fast_excel.xlsx"
      tmp_file = true
    end

    filename = filename.to_s if defined?(Pathname) && filename.is_a?(Pathname)

    opt = Libxlsxwriter::WorkbookOptions.new
    opt[:constant_memory] = constant_memory ? 1 : 0
    workbook = Libxlsxwriter.workbook_new_opt(filename, opt)

    result = Libxlsxwriter::Workbook.new(workbook)

    if default_format
      raise "default_format argument must be a hash" unless default_format.is_a?(Hash)
      result.default_format.set(default_format)
    end

    result.tmp_file = tmp_file
    result.filename = filename
    result
  end

  module WorkbookExt
    include AttributeHelper
    attr_accessor :tmp_file, :is_open, :filename

    def initialize(struct)
      @is_open = true
      @sheet_names = Set.new
      @sheets = []
      super(struct)
    end

    def add_format(options = nil)
      new_format = super()
      new_format.set(options) if options
      new_format
    end

    def bold_cell_format
      bold = add_format
      bold.set_bold
      bold
    end

    alias_method :bold_format, :bold_cell_format

    # "#,##0.00"
    # "[$-409]m/d/yy h:mm AM/PM;@"
    def number_format(pattern)
      format = add_format
      format.set_num_format(pattern)
      format
    end

    def add_worksheet(sheetname = nil)
      if !sheetname.nil?
        error = validate_worksheet_name(sheetname)
        if error != :no_error
          error_code = ERROR_ENUM.find(error)
          error_str = error_code ? Libxlsxwriter.strerror(error_code) : ''
          raise ArgumentError, "Invalid worksheet name '#{sheetname}': (#{error_code} - #{error}) #{error_str}"
        end
      end

      sheet = super(sheetname)
      sheet.workbook = self
      @sheets << sheet
      @sheet_names << sheet[:name]
      sheet
    end

    def get_worksheet_by_name(name)
      sheet = super(name)
      return nil if sheet.to_ptr.null?

      sheet.workbook = self

      sheet
    end

    def close
      @is_open = false
      @sheets.each(&:close)
      super
    end

    def read_string
      close if @is_open
      File.open(filename, 'rb', &:read)
    ensure
      remove_tmp_folder
    end

    def remove_tmp_folder
      FileUtils.remove_entry(File.dirname(filename)) if tmp_file
    end

    def constant_memory?
      #FastExcel.print_ffi_obj(self[:options])
      @constant_memory ||= self[:options][:constant_memory] != 0
    end
  end
end
