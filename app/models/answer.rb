class Answer < ApplicationRecord
  belongs_to :question, touch: true
  belongs_to :user, optional: true

  broadcasts_refreshes_to ->(answer) { answer.question.tree }

  normalizes :author_name, with: -> { it.squish.presence }

  validates :body, presence: true, length: { maximum: 2_000 }
  validates :author_name, length: { maximum: 100 }

  scope :chronological, -> { order(:created_at, :id) }

  def accepted? = accepted_at.present?

  def author = user&.name || author_name || I18n.t("answers.someone")
end
