require "test_helper"

class EventDatingTest < ActiveSupport::TestCase
  setup do
    @person = trees(:alpha).people.create!(given_names: "Anna")
  end

  test "saving a typed date fills in the sortable range, and changing it recomputes" do
    event = @person.events.create!(kind: "BIRT", date_raw: "14 мая 1781")
    assert_equal [ Date.new(1781, 5, 14), Date.new(1781, 5, 14), "day" ], event.values_at(:date_start, :date_end, :date_precision)

    event.update!(date_raw: "весна 1812")
    assert_equal [ nil, nil, nil ], event.values_at(:date_start, :date_end, :date_precision)
  end

  test "someone born more than 120 years ago counts as dead even without a death record" do
    @person.events.create!(kind: "BIRT", date_raw: "14 мая 1781")

    assert_not @person.living?
    assert_includes Person.visible_to(nil), @person
  end

  test "screens get a label in the reader's language, or the typed text" do
    I18n.with_locale(:ru) do
      assert_equal "14 мая 1781", @person.events.create!(kind: "BIRT", date_raw: "14 MAY 1781").date_label
      assert_equal "весна 1812", @person.events.create!(kind: "RESI", date_raw: "весна 1812").date_label
    end
  end

  test "life years keep a fuzzy date's qualifier" do
    @person.events.create!(kind: "BIRT", date_raw: "ок. 1696")
    @person.events.create!(kind: "DEAT", date_raw: "14 МАЙ 1781")

    I18n.with_locale(:ru) { assert_equal "ок. 1696 – 1781", @person.life_years }
  end

  test "export writes GEDCOM dates, and a phrase for text that isn't a date" do
    @person.events.create!(kind: "BIRT", date_raw: "ок. 1696")
    @person.events.create!(kind: "RESI", date_raw: "весна 1812")
    ged = Gedcom::Writer.new(trees(:alpha), user: users(:one)).to_gedcom

    assert_match(/1 BIRT\n2 DATE ABT 1696/, ged)
    assert_match(/1 RESI\n2 DATE \(весна 1812\)/, ged)

    target = trees(:beta)
    Gedcom::Mapper.new(Gedcom::Parser.new(ged).parse[:records], tree: target).import!
    assert_equal "весна 1812", target.events.find_by!(kind: "RESI").date_raw
  end
end
