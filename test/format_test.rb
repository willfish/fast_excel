require_relative 'test_helper'

describe "FastExcel::FormatExt align" do

  before do
    @workbook = FastExcel.open(constant_memory: true)
    @format = @workbook.add_format
  end

  it "should give default aligns" do
    assert_equal({horizontal: :align_none, vertical: :align_none}, @format.align)
  end

  it "should set align by full name" do
    @format.align = :align_center
    assert_equal({horizontal: :align_center, vertical: :align_none}, @format.align)
  end

  it "should set by string" do
    @format.align = "align_center"
    assert_equal({horizontal: :align_center, vertical: :align_none}, @format.align)
  end

  it "should set by short name" do
    @format.align = :center
    assert_equal({horizontal: :align_center, vertical: :align_none}, @format.align)
  end

  it "should set by hash" do
    @format.align = {v: "center", h: "center"}
    assert_equal({horizontal: :align_center, vertical: :align_vertical_center}, @format.align)
  end

  it "should raise exception for unknown value" do
    error = assert_raises(ArgumentError) do
      @format.align = :aaa
    end

    assert_equal(error.message, "Can not set align = :aaa, possible values are: [:align_none, :align_left, "\
      ":align_center, :align_right, :align_fill, :align_justify, :align_center_across, :align_distributed, "\
      ":align_vertical_top, :align_vertical_bottom, :align_vertical_center, :align_vertical_justify, :align_vertical_distributed]")
  end

  it "should raise exception for unknown hash key" do
    error = assert_raises(ArgumentError) do
      @format.align = {aaa: 1}
    end

    assert_equal(error.message, "Not allowed keys for align: [:aaa], possible keys: [:horizontal, :h, :vertical, :v]")
  end

  it "should get and set" do
    @format.align = {h: :center, v: :center}
    format2 = @workbook.add_format(align: @format.align)

    assert_equal({horizontal: :align_center, vertical: :align_vertical_center}, format2.align)
  end

end


describe "FastExcel::FormatExt colors" do

  before do
    workbook = FastExcel.open(constant_memory: true)
    @format = workbook.add_format
  end

  it "should set font color as hex num" do
    @format.font_color = 0xFF0000
    assert_equal(0xFF0000, @format.font_color)
  end

  it "should set font color as hex string" do
    @format.font_color = '0xFF0000'
    assert_equal(0xFF0000, @format.font_color)
  end

  it "should set font color as css hex string" do
    @format.font_color = '#FF0000'
    assert_equal(0xFF0000, @format.font_color)
  end

  it "should set font color as short hex string" do
    @format.font_color = 'FF0000'
    assert_equal(0xFF0000, @format.font_color)
  end

  it "should set font color as name" do
    @format.font_color = 'red'
    assert_equal(0xFF0000, @format.font_color)
  end

  it "should set font color as libxlsxwriter color enum name" do
    @format.font_color = 'color_red'
    assert_equal(0xFF0000, @format.font_color)
  end

  it "should set font color as short libxlsxwriter color enum name" do
    @format.font_color = 'blue'
    assert_equal(0x0000FF, @format.font_color)
  end

  it "should set font css color" do
    @format.font_color = 'alice_blue'
    assert_equal(0xF0F8FF, @format.font_color)
  end

  it "should allow to use symbol" do
    @format.font_color = :alice_blue
    assert_equal(0xF0F8FF, @format.font_color)
  end

  it "should have long method for border colors" do
    @format.border_bottom_color = :alice_blue
    assert_equal(0xF0F8FF, @format.border_bottom_color)
    assert_equal(0xF0F8FF, @format.bottom_color)
  end

  it "should raise for unexpected type" do
    error = assert_raises(ArgumentError) do
      @format.font_color = {aaa: 1}
    end

    if error.message =~ /=>/
      assert_equal(error.message, "Can not use Hash ({:aaa=>1}) for color value, expected String or Hex Number")
    else
      assert_equal(error.message, "Can not use Hash ({aaa: 1}) for color value, expected String or Hex Number")
    end
  end

  it "should raise for unexpected color" do
    error = assert_raises(ArgumentError) do
      @format.font_color = :aaa
    end

    assert_equal(error.message, "Unknown color value :aaa, expected hex string or color name")
  end

end


describe "FastExcel::FormatExt border" do

  before do
    workbook = FastExcel.open(constant_memory: true)
    @format = workbook.add_format
  end

  it "should set border as symbol" do
    @format.bottom = :border_thin
    assert_equal(:border_thin, @format.bottom)
  end

  it "should set border as short symbol" do
    @format.bottom = :thin
    assert_equal(:border_thin, @format.bottom)
  end

  it "should set border as string" do
    @format.bottom = "thin"
    assert_equal(:border_thin, @format.bottom)
  end

  it "should set border as number" do
    @format.bottom = 1
    assert_equal(:border_thin, @format.bottom)
  end

  it "should set border with long prop name" do
    error = assert_raises(ArgumentError) do
      @format.border_bottom = :aaa
    end

    assert_equal(error.message, "Unknown value :aaa for border. Possible values: "\
      "[:none, :thin, :medium, :dashed, :dotted, :thick, :double, :hair, :medium_dashed, "\
      ":dash_dot, :medium_dash_dot, :dash_dot_dot, :medium_dash_dot_dot, :slant_dash_dot]")
  end

  it "should get value with long name" do
    @format.bottom = "thin"
    assert_equal(:border_thin, @format.border_bottom)
  end

  it "should define aliases" do
    @format.font_size = 20
    assert_equal(@format.font_size, 20)

    @format.font_name = "XXX"
    assert_equal(@format.font_name, "XXX")
  end

  it "should raise when font size is negative" do
    error = assert_raises(ArgumentError) do
      @format.font_size = -1
    end

    assert_equal("font size should be >= 0 (use 0 for user default font size)", error.message)
  end

end

describe "FastExcel::AttributeHelper" do
  it "should set public writers on non-format wrappers" do
    workbook = FastExcel.open(constant_memory: true)
    worksheet = workbook.add_worksheet

    worksheet.set(auto_width: true)

    assert(worksheet.auto_width?)
  end

  it "should set raw fields on non-format wrappers" do
    workbook = FastExcel.open(constant_memory: true)

    workbook.set(active_sheet: 1)

    assert_equal(1, workbook[:active_sheet])
  end

  it "should expose fields as a hash" do
    workbook = FastExcel.open(constant_memory: true)
    format = workbook.add_format(font_size: 14)

    assert_equal(14, format.fields_hash[:font_size])
  end

  it "should pretty print fields" do
    workbook = FastExcel.open(constant_memory: true)
    format = workbook.add_format(font_size: 14)

    output = capture_io do
      PP.pp(format)
    end.first

    assert_match(/(?:font_size: 14\.0|:font_size=>14(?:\.0)?)/, output)
  end
end

describe "FastExcel::FormatExt option normalization" do
  it "rejects raw format struct fields through add_format options" do
    workbook = FastExcel.open(constant_memory: true)

    error = assert_raises(ArgumentError) do
      workbook.add_format(text_h_align: 999)
    end

    assert_equal("Unknown format option :text_h_align", error.message)
  end
end
