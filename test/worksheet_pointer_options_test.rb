require_relative "test_helper"
require "open3"
require "rbconfig"
require "zip"

describe "FastExcel worksheet pointer-backed options" do
  before do
    @workbook = FastExcel.open(constant_memory: false)
    @worksheet = @workbook.add_worksheet
  end

  def read_xlsx_entry(path)
    @workbook.close

    Zip::File.open(@workbook.filename) do |zip|
      entry = zip.read(path)
      entry.respond_to?(:read) ? entry.read : entry
    end
  end

  it "writes table options with column headers" do
    @worksheet.append_row(["Code", "Status"])
    @worksheet.append_row(["0101000000", "Active"])
    @worksheet.add_table(0, 0, 1, 1, name: "Commodities", style: "TableStyleMedium4", columns: ["Code", "Status"])

    table_xml = read_xlsx_entry("xl/tables/table1.xml")

    assert_includes(table_xml, 'ref="A1:B2"')
    assert_includes(table_xml, 'name="Commodities"')
    assert_includes(table_xml, 'name="Code"')
    assert_includes(table_xml, 'name="Status"')
    assert_includes(table_xml, 'name="TableStyleMedium4"')
  end

  it "writes rich strings from fragments" do
    bold = @workbook.add_format(bold: true)
    rich_string = FastExcel::RichString.new([
      { text: "plain " },
      { text: "bold", format: bold }
    ])

    @worksheet.write_value(0, 0, rich_string)

    assert_equal([["<html>plain <b>bold</b></html>"]], get_arrays(@workbook))
  end

  it "writes horizontal and vertical page breaks from arrays" do
    @worksheet.set_h_pagebreaks([10, 30])
    @worksheet.set_v_pagebreaks([2, 4])

    sheet_xml = read_xlsx_entry("xl/worksheets/sheet1.xml")

    assert_includes(sheet_xml, '<rowBreaks count="2" manualBreakCount="2">')
    assert_includes(sheet_xml, '<colBreaks count="2" manualBreakCount="2">')
    assert_includes(sheet_xml, '<brk id="10"')
    assert_includes(sheet_xml, '<brk id="30"')
    assert_includes(sheet_xml, '<brk id="2"')
    assert_includes(sheet_xml, '<brk id="4"')
  end

  it "keeps table pointer building available from the low-level binding require path" do
    script = <<~RUBY
      require "tmpdir"
      require "fast_excel/binding"

      filename = File.join(Dir.mktmpdir, "binding-table.xlsx")
      workbook = Libxlsxwriter::Workbook.new(Libxlsxwriter.workbook_new(filename))
      worksheet = workbook.add_worksheet(nil)
      worksheet.add_table(0, 0, 1, 0, columns: ["A"])
      workbook.close

      puts File.exist?(filename)
    RUBY

    stdout, stderr, status = Open3.capture3(RbConfig.ruby, "-Ilib", "-e", script)

    assert(status.success?, stderr)
    assert_equal("true", stdout.strip)
  end
end
