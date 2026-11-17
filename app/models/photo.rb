class Photo < ApplicationRecord
  CONTENT_TYPES = Person::AVATAR_CONTENT_TYPES
  MAX_BYTES     = 15.megabytes

  belongs_to :person
  belongs_to :tree, default: -> { person&.tree }

  has_one_attached :image do |attachable|
    attachable.variant :print, resize_to_limit: [ 640, 640 ]
  end

  broadcasts_refreshes_to :tree

  validate :image_is_a_photo
  before_save { self.taken_year = taken.to_s[/\d{4}/]&.to_i }

  scope :album, -> { order(Arel.sql("taken_year IS NULL, taken_year"), :id) }

  private
    def image_is_a_photo
      return errors.add(:image, :blank) unless image.attached?

      errors.add(:image, :invalid_content_type) unless image.content_type.in?(CONTENT_TYPES)
      errors.add(:image, :too_large) if image.byte_size > MAX_BYTES
    end
end
