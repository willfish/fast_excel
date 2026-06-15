require_relative "test_helper"
require_relative "../benchmarks/string_escaping"

describe "FastExcel::Benchmarks::StringEscaping" do
  it "matches libxlsxwriter escaping for XML text" do
    samples = [
      "plain ascii",
      "cafe au lait",
      "商品分類",
      "a&b<c>d",
      "bad\u0001control",
      "mixed & <tag> \u0002"
    ]

    samples.each do |sample|
      assert_equal(
        FastExcel::Benchmarks::StringEscaping.native_escape(sample).bytes,
        FastExcel::Benchmarks::StringEscaping.scan_then_native_escape(sample).bytes
      )
    end
  end

  it "does not mark ordinary UTF-8 strings as requiring native escaping" do
    refute(FastExcel::Benchmarks::StringEscaping.needs_native_escape?("plain ascii"))
    refute(FastExcel::Benchmarks::StringEscaping.needs_native_escape?("商品分類"))
  end

  it "marks XML special characters and controls as requiring native escaping" do
    assert(FastExcel::Benchmarks::StringEscaping.needs_native_escape?("a&b"))
    assert(FastExcel::Benchmarks::StringEscaping.needs_native_escape?("a<b"))
    assert(FastExcel::Benchmarks::StringEscaping.needs_native_escape?("a>b"))
    assert(FastExcel::Benchmarks::StringEscaping.needs_native_escape?("bad\u0001control"))
  end
end
