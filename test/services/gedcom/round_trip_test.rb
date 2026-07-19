require "test_helper"

# Deep round-trip: import → export → re-import must preserve CONTENT, not just record
# counts. Guards against a writer that silently drops names, sex, dates, places, family
# links, or unknown tags — all of which the count-only check in WriterTest would miss.
class Gedcom::RoundTripTest < ActiveSupport::TestCase
  setup do
    @source = File.read(Rails.root.join("test/fixtures/gedcom/minimal_551.ged"))
  end

  def import(text, tree:)
    records = Gedcom::Parser.new(text).parse[:records]
    Gedcom::Mapper.new(records, tree:).import!
  end

  test "import → export → re-import preserves person, event and family content" do
    origin = trees(:alpha)
    import(@source, tree: origin)

    exported = Gedcom::Writer.new(origin, user: users(:one)).to_gedcom

    target = Tree.create!(name: "Reimport")
    import(exported, tree: target)

    johann = target.people.find_by(given_names: "Johann")
    maria  = target.people.find_by(given_names: "Maria")

    assert johann, "Johann should survive the round-trip"
    assert maria,  "Maria should survive the round-trip"
    assert_equal "Bach", johann.surname
    assert_equal "M",    johann.sex
    assert_equal "F",    maria.sex

    birth = johann.events.find_by(kind: "BIRT")
    assert birth, "birth event should be preserved"
    assert_equal "21 MAR 1685",        birth.date_raw
    assert_equal "Eisenach, Thuringia", birth.value

    family = target.families.first
    assert_equal 2, family.partners.count
    assert_includes family.partners, johann
    assert_includes family.partners, maria

    marr = family.events.find_by(kind: "MARR")
    assert marr, "marriage event should be preserved"
    assert_equal "1707", marr.date_raw
  end

  test "unknown tags survive the round-trip via gedcom_raw" do
    tree   = trees(:alpha)
    person = Person.create!(given_names: "Zed", sex: "U", tree: tree,
                            gedcom_xref: "@I9@",
                            gedcom_raw: [ { "tag" => "_CUSTOM", "value" => "keepme" } ])
    Event.create!(kind: "DEAT", eventable: person, tree: tree)

    exported = Gedcom::Writer.new(tree, user: users(:one)).to_gedcom
    assert_match(/1 _CUSTOM keepme/, exported)

    target = Tree.create!(name: "Reimport2")
    import(exported, tree: target)

    reimported = target.people.find_by(gedcom_xref: "@I9@")
    assert_equal [ { "tag" => "_CUSTOM", "value" => "keepme" } ], reimported.gedcom_raw
  end
end
