require "test_helper"

class SourceCitationTest < ActiveSupport::TestCase
  setup do
    @tree   = trees(:alpha)
    @person = Person.create!(sex: "U", tree: @tree)
    @event  = Event.create!(kind: "BIRT", eventable: @person, tree: @tree)
  end

  test "source requires title" do
    source = Source.new(tree: @tree)
    assert_not source.valid?
    assert source.errors[:title].any?
  end

  test "source requires tree" do
    source = Source.new(title: "Parish register")
    assert_not source.valid?
  end

  test "valid source is persisted" do
    source = Source.create!(title: "Parish register", tree: @tree)
    assert source.persisted?
  end

  test "citation links source to event" do
    source   = Source.create!(title: "Census 1891", tree: @tree)
    citation = Citation.create!(source: source, citable: @event)
    assert_equal source,  citation.source
    assert_equal @event,  citation.citable
  end

  test "event has_many citations and sources" do
    source = Source.create!(title: "Baptism record", tree: @tree)
    Citation.create!(source: source, citable: @event)

    assert_includes @event.citations.map(&:source), source
    assert_includes @event.sources, source
  end

  test "destroying citation does not destroy source" do
    source   = Source.create!(title: "Vital record", tree: @tree)
    citation = Citation.create!(source: source, citable: @event)
    citation.destroy!
    assert source.reload.persisted?
  end

  test "destroying source destroys its citations" do
    source   = Source.create!(title: "Old record", tree: @tree)
    citation = Citation.create!(source: source, citable: @event)
    source.destroy!
    assert_raises(ActiveRecord::RecordNotFound) { citation.reload }
  end
end
