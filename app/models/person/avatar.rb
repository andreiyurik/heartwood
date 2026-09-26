module Person::Avatar
  extend ActiveSupport::Concern

  AVATAR_CONTENT_TYPES = %w[image/jpeg image/png image/webp image/gif].freeze
  AVATAR_MAX_BYTES     = 5.megabytes

  included do
    has_one_attached :avatar

    validate :avatar_is_an_image, if: -> { avatar.attached? }
  end

  private
    def avatar_is_an_image
      errors.add(:avatar, :invalid_content_type) unless avatar.content_type.in?(AVATAR_CONTENT_TYPES)
      errors.add(:avatar, :too_large) if avatar.byte_size > AVATAR_MAX_BYTES
    end
end
