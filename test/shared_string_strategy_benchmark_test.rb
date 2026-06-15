require_relative "test_helper"
require_relative "../benchmarks/shared_string_strategy"

describe "FastExcel::Benchmarks::SharedStringStrategy" do
  def workbook_content(constant_memory:)
    workbook = FastExcel.open(constant_memory: constant_memory)
    worksheet = workbook.add_worksheet("Strings")

    3.times do |row_number|
      worksheet.write_value(row_number, 0, "Repeated")
    end

    workbook.read_string
  end

  it "detects inline strings in constant-memory workbooks" do
    profile = FastExcel::Benchmarks::SharedStringStrategy.archive_profile(workbook_content(constant_memory: true))

    refute(profile.fetch(:shared_strings_xml))
    assert_operator(profile.fetch(:inline_string_cells), :>, 0)
  end

  it "detects shared strings in normal-memory workbooks" do
    profile = FastExcel::Benchmarks::SharedStringStrategy.archive_profile(workbook_content(constant_memory: false))

    assert(profile.fetch(:shared_strings_xml))
    assert_operator(profile.fetch(:shared_string_items), :>, 0)
    assert_equal(0, profile.fetch(:inline_string_cells))
  end

  it "profiles repeated, unique, and mixed datasets across both modes" do
    result = FastExcel::Benchmarks::SharedStringStrategy::Profile.new(rows: 5, columns: 3).run.to_h

    assert_equal([:mixed, :repeated, :unique], result.fetch(:datasets).keys.sort)
    assert_equal([:constant_memory_inline_strings, :normal_memory_shared_strings], result.fetch(:datasets).fetch(:repeated).keys.sort)
  end
end
