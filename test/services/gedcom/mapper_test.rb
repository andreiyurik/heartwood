require "test_helper"

class Gedcom::MapperTest < ActiveSupport::TestCase
  setup do
    @tree = trees(:alpha)
  end

  # Parse GEDCOM text and run the mapper using the test tree.
  def import(gedcom_text)
    records = Gedcom::Parser.new(gedcom_text).parse[:records]
    Gedcom::Mapper.new(records, tree: @tree).import!
  end

  # --- INDI → Person ---

  test "maps INDI to Person with gedcom_xref and sex" do
    result = import(<<~GED)
      0 @I1@ INDI
      1 NAME Johann /Bach/
      1 SEX M
    GED
    assert_equal 1, result[:people].size
    person = result[:people].first
    assert_equal "@I1@", person.gedcom_xref
    assert_equal "M",    person.sex
  end

  test "parses NAME value into given_names and surname" do
    result = import(<<~GED)
      0 @I1@ INDI
      1 NAME Johann /Bach/
    GED
    person = result[:people].first
    assert_equal "Johann", person.given_names
    assert_equal "Bach",   person.surname
  end

  test "prefers GIVN and SURN sub-tags over NAME string parsing" do
    result = import(<<~GED)
      0 @I1@ INDI
      1 NAME Johann Sebastian /Bach/
      2 GIVN Johann Sebastian
      2 SURN Bach
    GED
    person = result[:people].first
    assert_equal "Johann Sebastian", person.given_names
    assert_equal "Bach",             person.surname
  end

  test "defaults sex to U when SEX tag is absent" do
    result = import("0 @I1@ INDI\n")
    assert_equal "U", result[:people].first.sex
  end

  # --- Events on Person ---

  test "maps BIRT with DATE to Event on Person" do
    result = import(<<~GED)
      0 @I1@ INDI
      1 SEX M
      1 BIRT
      2 DATE 21 MAR 1685
    GED
    person = result[:people].first
    birth  = person.events.find_by(kind: "BIRT")
    assert_not_nil birth
    assert_equal "21 MAR 1685", birth.date_raw
  end

  test "maps BIRT with PLAC to Event value on Person" do
    result = import(<<~GED)
      0 @I1@ INDI
      1 BIRT
      2 DATE 21 MAR 1685
      2 PLAC Eisenach, Thuringia
    GED
    birth = result[:people].first.events.find_by(kind: "BIRT")
    assert_equal "Eisenach, Thuringia", birth.value
  end

  test "maps DEAT event to Person" do
    result = import(<<~GED)
      0 @I1@ INDI
      1 SEX M
      1 DEAT
      2 DATE 28 JUL 1750
    GED
    person = result[:people].first
    assert_not_nil person.events.find_by(kind: "DEAT")
  end

  # --- FAM → Family + joins ---

  test "maps FAM to Family with gedcom_xref" do
    result = import(<<~GED)
      0 @I1@ INDI
      1 SEX M
      0 @F1@ FAM
      1 HUSB @I1@
    GED
    assert_equal 1, result[:families].size
    assert_equal "@F1@", result[:families].first.gedcom_xref
  end

  test "maps HUSB and WIFE to FamilyPartner joins" do
    result = import(<<~GED)
      0 @I1@ INDI
      1 SEX M
      0 @I2@ INDI
      1 SEX F
      0 @F1@ FAM
      1 HUSB @I1@
      1 WIFE @I2@
    GED
    fam = result[:families].first
    assert_equal 2, fam.partners.count
    xrefs = fam.partners.map(&:gedcom_xref)
    assert_includes xrefs, "@I1@"
    assert_includes xrefs, "@I2@"
  end

  test "maps CHIL to FamilyChild join" do
    result = import(<<~GED)
      0 @I1@ INDI
      1 SEX M
      0 @I2@ INDI
      1 SEX F
      0 @I3@ INDI
      1 SEX U
      0 @F1@ FAM
      1 HUSB @I1@
      1 WIFE @I2@
      1 CHIL @I3@
    GED
    fam = result[:families].first
    assert_equal 1, fam.children.count
    assert_equal "@I3@", fam.children.first.gedcom_xref
  end

  # --- Events on Family ---

  test "maps MARR with DATE to Event on Family" do
    result = import(<<~GED)
      0 @I1@ INDI
      1 SEX M
      0 @I2@ INDI
      1 SEX F
      0 @F1@ FAM
      1 HUSB @I1@
      1 WIFE @I2@
      1 MARR
      2 DATE 1707
    GED
    fam  = result[:families].first
    marr = fam.events.find_by(kind: "MARR")
    assert_not_nil marr
    assert_equal "1707", marr.date_raw
  end

  # --- Unknown tags → gedcom_raw ---

  test "preserves unknown tags in gedcom_raw on Person" do
    result = import(<<~GED)
      0 @I1@ INDI
      1 SEX M
      1 _CUSTOM some value
      1 _UID A1B2C3D4
    GED
    person = result[:people].first
    assert_not_nil person.gedcom_raw
    tags = person.gedcom_raw.map { |r| r["tag"] }
    assert_includes tags, "_CUSTOM"
    assert_includes tags, "_UID"
  end

  test "Person with only known tags has nil gedcom_raw" do
    result = import(<<~GED)
      0 @I1@ INDI
      1 SEX F
      1 NAME Anna /Bach/
    GED
    assert_nil result[:people].first.gedcom_raw
  end

  # --- Warnings for unresolvable xrefs ---

  test "records a warning for an unresolved xref pointer" do
    result = import(<<~GED)
      0 @F1@ FAM
      1 HUSB @I99@
    GED
    assert result[:warnings].any? { |w| w.include?("@I99@") }
  end

  # --- Full fixture ---

  test "imports minimal_551 fixture: 2 people, 1 family, no warnings" do
    result = import(File.read(Rails.root.join("test/fixtures/gedcom/minimal_551.ged")))

    assert_empty result[:warnings]
    assert_equal 2, result[:people].size
    assert_equal 1, result[:families].size
    fam = result[:families].first
    assert fam.events.exists?(kind: "MARR")
  end

  test "import assigns all records to the given tree" do
    result = import(<<~GED)
      0 @I1@ INDI
      1 SEX M
      0 @I2@ INDI
      1 SEX F
      0 @F1@ FAM
      1 HUSB @I1@
      1 WIFE @I2@
      1 MARR
      2 DATE 1900
    GED

    assert result[:people].all? { |p| p.tree == @tree }
    assert result[:families].all? { |f| f.tree == @tree }
    assert result[:families].first.events.all? { |e| e.tree == @tree }
  end
end
