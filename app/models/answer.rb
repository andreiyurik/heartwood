class Answer < ApplicationRecord
  belongs_to :question, touch: true
  belongs_to :user, optional: true
  belongs_to :kept_photo, class_name: "Photo", optional: true

  has_one_attached :photo do |attachable|
    attachable.variant :print, resize_to_limit: [ 640, 640 ]
  end

  broadcasts_refreshes_to ->(answer) { answer.question.tree }

  attribute :body, default: ""

  normalizes :author_name, with: -> { it.squish.presence }

  validates :body, presence: true, unless: -> { photo.attached? }
  validates :body, length: { maximum: 2_000 }
  validate :photo_is_a_picture, if: -> { photo.attached? }
  validates :author_name, length: { maximum: 100 }

  scope :chronological, -> { order(:created_at, :id) }

  after_create_commit :tell_the_asker, if: :worth_a_letter?

  def accepted? = accepted_at.present?

  def author = user&.name || author_name || I18n.t("answers.someone")

  # A copy, not the same file: the answer's own photo goes when the answer does.
  def keep_photo!
    with_lock do
      kept_photo || begin
      question.person.photos.create!(image: { io: StringIO.new(photo.download), filename: photo.filename.to_s,
        content_type: photo.content_type }).tap { update!(kept_photo: it) }
      end
    end
  end

  private
    def photo_is_a_picture
      errors.add(:photo, :invalid_content_type) unless photo.content_type.in?(Photo::CONTENT_TYPES)
      errors.add(:photo, :too_large) if photo.byte_size > Photo::MAX_BYTES
    end

    def tell_the_asker
      QuestionsMailer.answered(self).deliver_later
    end

    # One letter for a burst of answers: the first in an hour, never for the asker's own.
    def worth_a_letter?
      asker = question.asker
      asker && asker != user && asker.answer_emails? &&
        !question.answers.where(created_at: (created_at - 1.hour)...created_at).where.not(id: id).exists?
    end
end
