# Place (PLAC) — a normalized location attached to events. We keep the raw GEDCOM
# string for a lossless round-trip and, when geocoding succeeds, coordinates that
# put the place on a map. No coordinates simply means no pin. See place.md.
class Place < ApplicationRecord
  include BelongsToTree

  has_many :events, dependent: :nullify

  validates :name, presence: true

  # Geocode a freshly created place in the background; a flaky lookup just leaves
  # it pin-less, never blocks the user (see PlaceGeocodeJob).
  after_create_commit :geocode_later

  scope :search, ->(query) {
    q = query.to_s.strip
    next none if q.blank?
    where("name LIKE ?", "%#{sanitize_sql_like(q)}%").order(:name)
  }

  def geocoded? = latitude.present? && longitude.present?

  def geocode_later
    PlaceGeocodeJob.perform_later(self) unless geocoded?
  end
end
