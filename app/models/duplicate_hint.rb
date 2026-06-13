# A suggested duplicate pair surfaced by DuplicateFinder. Stays "pending" until a
# user either dismisses it or (a v2 feature) merges. We never act on it ourselves.
class DuplicateHint < ApplicationRecord
  include BelongsToTree

  belongs_to :person_a, class_name: "Person"
  belongs_to :person_b, class_name: "Person"

  enum :status, { pending: "pending", confirmed: "confirmed", dismissed: "dismissed" }, default: "pending"

  validates :score, presence: true
end
