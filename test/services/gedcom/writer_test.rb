require "test_helper"

class Gedcom::WriterTest < ActiveSupport::TestCase
  setup do
    @tree   = trees(:alpha)
    @member = users(:one)   # owns tree :alpha
    @other  = trees(:beta)
  end

  # Parse then re-import a GEDCOM string into a fresh tree, return the result.
  def reimport(gedcom_text, tree:)
    records = Gedcom::Parser.new(gedcom_text).parse[:records]
    Gedcom::Mapper.new(records, tree:).import!
  end

  # ---------------------------------------------------------------------------
  # Round-trip: import → export → re-import → structurally stable
  # ---------------------------------------------------------------------------

  test "round-trip import→export→re-import is structurally stable" do
    ged_source = File.read(Rails.root.join("test/fixtures/gedcom/minimal_551.ged"))
    first = reimport(ged_source, tree: @tree)

    exported = Gedcom::Writer.new(@tree, user: @member).to_gedcom

    reimport_tree = Tree.create!(name: "Reimport")
    second = reimport(exported, tree: reimport_tree)

    assert_equal first[:people].size,   second[:people].size,   "person count differs"
    assert_equal first[:families].size, second[:families].size, "family count differs"
  end

  test "exported GEDCOM has HEAD and TRLR" do
    ged = Gedcom::Writer.new(@tree, user: @member).to_gedcom
    assert_match(/\A0 HEAD\n/, ged)
    assert_match(/\n0 TRLR\z/, ged)
  end

  # ---------------------------------------------------------------------------
  # Tree scoping: only Current.tree records are exported
  # ---------------------------------------------------------------------------

  test "export contains only records from the requested tree" do
    person_alpha = Person.create!(given_names: "Alpha", sex: "U", tree: @tree)
    Event.create!(kind: "DEAT", eventable: person_alpha, tree: @tree)  # make visible

    person_beta = Person.create!(given_names: "Beta", sex: "U", tree: @other)
    Event.create!(kind: "DEAT", eventable: person_beta, tree: @other)

    ged = Gedcom::Writer.new(@tree, user: @member).to_gedcom

    assert_match "Alpha", ged
    assert_no_match(/Beta/, ged)
  end

  # ---------------------------------------------------------------------------
  # Living-person redaction for non-member exports
  # ---------------------------------------------------------------------------

  test "living person is omitted from non-member export" do
    living = Person.create!(given_names: "Alive", sex: "U", tree: @tree)
    dead   = Person.create!(given_names: "Dead", sex: "U", tree: @tree)
    Event.create!(kind: "DEAT", eventable: dead, tree: @tree)

    outsider = users(:two)
    ged = Gedcom::Writer.new(@tree, user: outsider).to_gedcom

    assert_no_match(/Alive/, ged)
    assert_match "Dead",  ged
  end

  test "living person is included in member export" do
    living = Person.create!(given_names: "Alive", sex: "U", tree: @tree)

    ged = Gedcom::Writer.new(@tree, user: @member).to_gedcom
    assert_match "Alive", ged
  end

  # ---------------------------------------------------------------------------
  # GEDCOM format correctness
  # ---------------------------------------------------------------------------

  test "emits INDI record with NAME GIVN SURN and SEX" do
    Person.create!(given_names: "Johann", surname: "Bach", sex: "M", tree: @tree).tap do |p|
      Event.create!(kind: "DEAT", eventable: p, tree: @tree)
    end

    ged = Gedcom::Writer.new(@tree, user: nil).to_gedcom

    assert_match(/1 NAME Johann \/Bach\//, ged)
    assert_match(/2 GIVN Johann/, ged)
    assert_match(/2 SURN Bach/, ged)
    assert_match(/1 SEX M/, ged)
  end

  test "emits event with DATE and PLAC" do
    p = Person.create!(sex: "U", tree: @tree)
    Event.create!(kind: "BIRT", eventable: p, tree: @tree,
                  date_raw: "21 MAR 1685", value: "Eisenach")

    ged = Gedcom::Writer.new(@tree, user: @member).to_gedcom

    assert_match(/1 BIRT\n2 DATE 21 MAR 1685\n2 PLAC Eisenach/, ged)
  end

  test "emits FAM with HUSB WIFE and CHIL" do
    father = Person.create!(sex: "M", tree: @tree)
    mother = Person.create!(sex: "F", tree: @tree)
    child  = Person.create!(sex: "U", tree: @tree)
    fam    = Family.create!(tree: @tree)
    fam.partners << father << mother
    fam.children << child

    ged = Gedcom::Writer.new(@tree, user: @member).to_gedcom

    assert_match(/1 HUSB/, ged)
    assert_match(/1 WIFE/, ged)
    assert_match(/1 CHIL/, ged)
  end

  test "family omits invisible children from non-member export" do
    father  = Person.create!(sex: "M", tree: @tree)
    Event.create!(kind: "DEAT", eventable: father, tree: @tree)
    living_child = Person.create!(given_names: "YoungOne", sex: "U", tree: @tree)
    fam = Family.create!(tree: @tree)
    fam.partners << father
    fam.children << living_child

    outsider = users(:two)
    ged = Gedcom::Writer.new(@tree, user: outsider).to_gedcom

    assert_no_match(/YoungOne/, ged)
    assert_no_match(/1 CHIL/, ged)
  end

  test "uses gedcom_xref for round-trip xref identity" do
    person = Person.create!(given_names: "Hans", sex: "M", tree: @tree,
                            gedcom_xref: "@I42@")
    Event.create!(kind: "DEAT", eventable: person, tree: @tree)

    ged = Gedcom::Writer.new(@tree, user: nil).to_gedcom
    assert_match(/^0 @I42@ INDI/, ged)
  end
end
