require "test_helper"

# Event (EVEN) — birth/death/marriage etc., attached polymorphically to a
# Person or a Family. See docs/domain/event.md, docs/domain/domain-model.md.
class EventTest < ActiveSupport::TestCase
  setup do
    @person = Person.create!(given_names: "Ada", surname: "Lovelace", sex: "F")
    @family = Family.create!
  end

  test "requires a kind" do
    event = Event.new(eventable: @person)
    assert_not event.valid?
    assert_includes event.errors[:kind], "can't be blank"
  end

  test "attaches to a person (eventable)" do
    event = @person.events.create!(kind: "BIRT", date_raw: "10 DEC 1815")
    assert_equal @person, event.eventable
    assert_includes @person.events, event
  end

  test "attaches to a family (eventable)" do
    event = @family.events.create!(kind: "MARR")
    assert_equal @family, event.eventable
    assert_includes @family.events, event
  end

  test "a person with no death event is considered living" do
    assert @person.living?
  end

  test "a person with a death event is not living" do
    @person.events.create!(kind: "DEAT", date_raw: "27 NOV 1852")
    assert_not @person.reload.living?
  end

  test "birth and death helpers return the vital events" do
    birth = @person.events.create!(kind: "BIRT")
    death = @person.events.create!(kind: "DEAT")
    assert_equal birth, @person.birth
    assert_equal death, @person.death
  end

  test "kind_label returns a human label for known GEDCOM tags" do
    assert_equal "Birth", Event.new(kind: "BIRT").kind_label
    assert_equal "Death", Event.new(kind: "DEAT").kind_label
    assert_equal "Occupation", Event.new(kind: "OCCU").kind_label
  end

  test "kind_label falls back to the raw tag when unknown" do
    assert_equal "XYZ", Event.new(kind: "XYZ").kind_label
  end

  test "summary shows the date for events and the value for facts" do
    assert_equal "10 DEC 1815", Event.new(kind: "BIRT", date_raw: "10 DEC 1815").summary
    assert_equal "Engineer", Event.new(kind: "OCCU", value: "Engineer").summary
  end
end
