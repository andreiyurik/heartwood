require "test_helper"

class Gedcom::ParserTest < ActiveSupport::TestCase
  # --- Line-level parsing ---

  test "parses a simple level-0 record-start line" do
    line = Gedcom::Parser.parse_line("0 @I1@ INDI")
    assert_equal 0,      line[:level]
    assert_equal "@I1@", line[:xref]
    assert_equal "INDI", line[:tag]
    assert_nil           line[:value]
  end

  test "parses a level-1 tag-value line" do
    line = Gedcom::Parser.parse_line("1 NAME Johann /Bach/")
    assert_equal 1,              line[:level]
    assert_nil                   line[:xref]
    assert_equal "NAME",         line[:tag]
    assert_equal "Johann /Bach/", line[:value]
  end

  test "parses a line with no value" do
    line = Gedcom::Parser.parse_line("1 BIRT")
    assert_equal 1,      line[:level]
    assert_nil           line[:xref]
    assert_equal "BIRT", line[:tag]
    assert_nil           line[:value]
  end

  test "parses a level-0 HEAD line with no xref" do
    line = Gedcom::Parser.parse_line("0 HEAD")
    assert_equal 0,      line[:level]
    assert_nil           line[:xref]
    assert_equal "HEAD", line[:tag]
  end

  test "parses a level-0 TRLR line" do
    line = Gedcom::Parser.parse_line("0 TRLR")
    assert_equal 0,      line[:level]
    assert_equal "TRLR", line[:tag]
  end

  test "returns nil for a blank line (tolerant)" do
    assert_nil Gedcom::Parser.parse_line("")
    assert_nil Gedcom::Parser.parse_line("   ")
  end

  test "returns nil for an unparseable line and records a warning (tolerant)" do
    parser = Gedcom::Parser.new("not a gedcom line at all")
    result = parser.parse
    assert result[:warnings].any? { |w| w.include?("not a gedcom line") }
  end

  # --- Record-tree parsing of a 5.5.1 fixture ---

  test "parses minimal 5.5.1 fixture into correct record counts" do
    src    = File.read(fixture_path("minimal_551.ged"))
    result = Gedcom::Parser.new(src).parse
    assert_empty result[:warnings], "Expected no warnings, got: #{result[:warnings].inspect}"

    individuals = result[:records].select { |r| r[:tag] == "INDI" }
    families    = result[:records].select { |r| r[:tag] == "FAM"  }

    assert_equal 2, individuals.size
    assert_equal 1, families.size
  end

  test "parses INDI record with correct xref and children" do
    src    = File.read(fixture_path("minimal_551.ged"))
    result = Gedcom::Parser.new(src).parse
    indi   = result[:records].find { |r| r[:xref] == "@I1@" }

    assert_not_nil indi
    assert_equal "INDI", indi[:tag]

    name_child = indi[:children].find { |c| c[:tag] == "NAME" }
    assert_not_nil name_child
    assert_equal "Johann /Bach/", name_child[:value]
  end

  test "parses BIRT sub-record with DATE and PLAC" do
    src    = File.read(fixture_path("minimal_551.ged"))
    result = Gedcom::Parser.new(src).parse
    indi   = result[:records].find { |r| r[:xref] == "@I1@" }
    birt   = indi[:children].find { |c| c[:tag] == "BIRT" }

    assert_not_nil birt
    date_child = birt[:children].find { |c| c[:tag] == "DATE" }
    plac_child = birt[:children].find { |c| c[:tag] == "PLAC" }
    assert_equal "21 MAR 1685",           date_child[:value]
    assert_equal "Eisenach, Thuringia",   plac_child[:value]
  end

  test "parses FAM record with HUSB and WIFE pointers" do
    src    = File.read(fixture_path("minimal_551.ged"))
    result = Gedcom::Parser.new(src).parse
    fam    = result[:records].find { |r| r[:tag] == "FAM" }

    husb = fam[:children].find { |c| c[:tag] == "HUSB" }
    wife = fam[:children].find { |c| c[:tag] == "WIFE" }
    assert_equal "@I1@", husb[:value]
    assert_equal "@I2@", wife[:value]
  end

  # --- GEDCOM 7.0 fixture ---

  test "parses minimal 7.0 fixture without warnings" do
    src    = File.read(fixture_path("minimal_70.ged"))
    result = Gedcom::Parser.new(src).parse
    assert_empty result[:warnings]
    assert_equal 1, result[:records].select { |r| r[:tag] == "INDI" }.size
  end

  # --- Tolerant: strips BOM ---

  test "strips UTF-8 BOM if present" do
    bom = "\xEF\xBB\xBF".b
    src = bom + "0 HEAD\n0 TRLR\n"
    result = Gedcom::Parser.new(src.force_encoding("UTF-8")).parse
    assert_empty result[:warnings]
  end

  private

  def fixture_path(name)
    Rails.root.join("test/fixtures/gedcom", name)
  end
end
