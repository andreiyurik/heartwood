# Event & Fact (EVEN) — anything that happened (birth, death, marriage) or any
# attribute that holds (occupation). Attached polymorphically to a Person or Family.
# `kind` is the GEDCOM tag (BIRT, DEAT, MARR, OCCU, ...). Dates keep the raw GEDCOM
# string plus a parsed range. See docs/domain/event.md.
class Event < ApplicationRecord
  include BelongsToTree

  # GEDCOM tag => human label. Extend freely; import preserves unknown tags.
  KINDS = {
    "BIRT" => "Birth", "DEAT" => "Death", "BAPM" => "Baptism", "BURI" => "Burial",
    "MARR" => "Marriage", "DIV" => "Divorce",
    "OCCU" => "Occupation", "RESI" => "Residence", "EDUC" => "Education"
  }.freeze

  # Kinds offered when adding an event to a Person (marriage/divorce belong to a Family).
  PERSON_KINDS = %w[BIRT DEAT BAPM BURI OCCU RESI EDUC].freeze

  belongs_to :eventable, polymorphic: true
  belongs_to :place, optional: true

  has_many :citations, as: :citable, dependent: :destroy
  has_many :sources,   through: :citations

  validates :kind, presence: true

  before_validation :inherit_tree_from_eventable
  before_validation :assign_place

  def kind_label
    I18n.t("events.kinds.#{kind}", default: KINDS.fetch(kind, kind))
  end

  # What to show next to the label: the date for events, the value for facts.
  def summary
    date_raw.presence || value.presence
  end

  # The place as free text — what the form edits. Reading falls back to the typed
  # name before the record is resolved; writing finds-or-creates a tree Place so
  # the same town typed twice collapses to one row (and earns one map pin).
  def place_name = @place_name || place&.name

  def place_name=(value)
    @place_name = value.to_s.strip
  end

  # Coordinates the user confirmed on the map picker. Optional — without them the
  # place is geocoded in the background instead (see PlaceGeocodeJob).
  attr_accessor :place_latitude, :place_longitude

  private

  def inherit_tree_from_eventable
    self.tree ||= eventable&.tree
  end

  def assign_place
    return if @place_name.nil?

    if @place_name.blank?
      self.place = nil
      return
    end

    # A Place is shared by name across the tree, so we only fill in coordinates
    # we don't already have — picking a spot for one event never moves the pin
    # for everyone else's events at the same place.
    found = tree.places.find_or_initialize_by(name: @place_name)
    if picked_coordinates? && !found.geocoded?
      found.latitude  = place_latitude
      found.longitude = place_longitude
    end
    found.save! if found.changed?

    self.place = found
  end

  def picked_coordinates?
    place_latitude.present? && place_longitude.present?
  end
end
