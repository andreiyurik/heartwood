class Question < ApplicationRecord
  PERSON_FIELDS = %w[ given_names surname birth_surname born died ].freeze
  PHOTO_FIELDS  = %w[ caption taken ].freeze

  belongs_to :tree, default: -> { person&.tree }
  belongs_to :person
  belongs_to :photo, optional: true
  belongs_to :asker, class_name: "User", optional: true
  belongs_to :closed_by, class_name: "User", optional: true

  has_many :answers, dependent: :delete_all
  has_secure_token :token, length: 32

  broadcasts_refreshes_to :tree

  validates :body, presence: true, length: { maximum: 500 }

  after_initialize { self.body ||= I18n.t("questions.photo_default") if new_record? && photo }

  scope :open,   -> { where(closed_at: nil) }
  scope :closed, -> { where.not(closed_at: nil) }
  scope :latest, -> { order(created_at: :desc, id: :desc) }

  def open? = closed_at.nil?
  def closed? = !open?

  def fields = photo ? PHOTO_FIELDS : PERSON_FIELDS

  def accept(answer, into:, text:, by:)
    raise ArgumentError, "#{into} is not a field of this question" unless into.in?(fields)

    transaction do
      (photo || person).update!(into => text)
      answer.update!(accepted_at: Time.current)
      close(by: by)
    end
  end

  def close(by:)
    update!(closed_at: Time.current, closed_by: by)
  end
end
