class Place < ApplicationRecord
  include BelongsToTree

  has_many :events, dependent: :nullify

  validates :name, presence: true

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
