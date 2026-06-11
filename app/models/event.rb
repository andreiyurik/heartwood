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

  validates :kind, presence: true

  before_validation :inherit_tree_from_eventable

  def kind_label
    I18n.t("events.kinds.#{kind}", default: KINDS.fetch(kind, kind))
  end

  # What to show next to the label: the date for events, the value for facts.
  def summary
    date_raw.presence || value.presence
  end

  private

  def inherit_tree_from_eventable
    self.tree ||= eventable&.tree
  end
end
