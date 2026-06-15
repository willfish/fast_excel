require_relative 'test_helper'

describe "FastExcel text_width" do

  it "should calculate text width" do
    workbook = FastExcel.open(constant_memory: false)
    sheet = workbook.add_worksheet
    sheet.auto_width = true

    sheet.append_row([
      "tini",
      "Longer",
      "Some longer text!",
      "This gem is FFI binding for libxlsxwriter C library"
    ])

    assert_equal(sheet.calculated_column_widths, {0 => 3.52, 1 => 5.28, 2 => 14.96, 3 => 44.88})
  end

  it "should set the default column width for an empty column on close" do
    workbook = FastExcel.open(constant_memory: false)
    sheet = workbook.add_worksheet
    sheet.auto_width = true

    sheet.append_row([
      nil,
      "tini",
      "Longer",
      "Some longer text!",
      "This gem is FFI binding for libxlsxwriter C library"
    ])

    assert_equal(sheet.calculated_column_widths, {0 => nil, 1 => 3.52, 2 => 5.28, 3 => 14.96, 4 => 44.88})

    workbook.close

    assert_equal(sheet.calculated_column_widths, {0 => FastExcel::DEF_COL_WIDTH, 1 => 3.52, 2 => 5.28, 3 => 14.96, 4 => 44.88})
  end

  it "should use explicit and column formats when calculating widths" do
    workbook = FastExcel.open(constant_memory: false)
    sheet = workbook.add_worksheet
    sheet.auto_width = true

    small = workbook.add_format(font_size: 10)
    large = workbook.add_format(font_size: 20)
    sheet.set_column(1, 1, nil, large)

    sheet.write_value(0, 0, FastExcel::URL.new("https://example.test"), small)
    sheet.write_value(0, 1, "large")

    assert_equal(16.0, sheet.calculated_column_widths[0])
    assert_equal(8.0, sheet.calculated_column_widths[1])
  end

  it "should track auto width only for written display text" do
    workbook = FastExcel.open(constant_memory: false)
    sheet = workbook.add_worksheet
    sheet.auto_width = true

    rich_string = FastExcel::RichString.new([
      { text: "ab" },
      { text: "cde" }
    ])

    sheet.write_value(0, 0, FastExcel::Formula.new("SUM(1,2)"))
    sheet.write_value(0, 1, FastExcel::URL.new("https://x.test"))
    sheet.write_value(0, 2, rich_string)

    assert_equal({1 => 12.32, 2 => 4.4}, sheet.calculated_column_widths)
  end
end
