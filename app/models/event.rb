# Event & Fact (EVEN) — anything that happened (birth, death, marriage) or any
# attribute that holds (occupation). Attached polymorphically to a Person or Family.
# `kind` is the GEDCOM tag (BIRT, DEAT, MARR, OCCU, ...). Dates keep the raw GEDCOM
# string plus a parsed range. See docs/domain/event.md.
class Event < ApplicationRecord
  belongs_to :eventable, polymorphic: true

  validates :kind, presence: true
end
