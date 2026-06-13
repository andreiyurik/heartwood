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

  private

  def inherit_tree_from_eventable
    self.tree ||= eventable&.tree
  end

  def assign_place
    return if @place_name.nil?
    self.place = @place_name.present? ? tree.places.find_or_create_by!(name: @place_name) : nil
  end
end
