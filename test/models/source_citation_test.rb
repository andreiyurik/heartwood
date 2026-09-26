require "test_helper"

class SourceCitationTest < ActiveSupport::TestCase
  setup do
    @tree   = trees(:bach)
    @person = people(:johann_sebastian)
    @event  = events(:sebastian_death)
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

  test "citation confidence defaults to normal" do
    source   = Source.create!(title: "Census 1901", tree: @tree)
    citation = Citation.create!(source: source, citable: @event)
    assert citation.normal?
  end

  test "citation confidence rejects an invalid level" do
    source = Source.create!(title: "Census 1901", tree: @tree)
    assert_raises(ArgumentError) do
      Citation.create!(source: source, citable: @event, confidence: "extremely_high")
    end
  end

  test "citation stores page, quoted text, date, and confidence" do
    source   = Source.create!(title: "Parish register", tree: @tree)
    citation = Citation.create!(
      source: source, citable: @event,
      page: "p. 42", text: "born the third of March", date: Date.new(1881, 4, 3),
      confidence: "very_high"
    )
    citation.reload
    assert_equal "p. 42", citation.page
    assert_equal "born the third of March", citation.text
    assert_equal Date.new(1881, 4, 3), citation.date
    assert citation.very_high?
  end

  test "citation confidence_label renders via I18n" do
    source   = Source.create!(title: "Census 1901", tree: @tree)
    citation = Citation.create!(source: source, citable: @event, confidence: "low")
    assert_equal I18n.t("citations.confidence.low"), citation.confidence_label
  end

  test "source stores author, repository, and source_type" do
    source = Source.create!(
      title: "1881 England Census", tree: @tree,
      author: "General Register Office", repository: "The National Archives",
      source_type: "census"
    )
    source.reload
    assert_equal "General Register Office", source.author
    assert_equal "The National Archives", source.repository
    assert_equal "census", source.source_type
  end
end
