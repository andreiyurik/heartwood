class Answer < ApplicationRecord
  belongs_to :question, touch: true
  belongs_to :user, optional: true

  broadcasts_refreshes_to ->(answer) { answer.question.tree }

  normalizes :author_name, with: -> { it.squish.presence }

  validates :body, presence: true, length: { maximum: 2_000 }
  validates :author_name, length: { maximum: 100 }

  scope :chronological, -> { order(:created_at, :id) }

  after_create_commit :tell_the_asker, if: :worth_a_letter?

  def accepted? = accepted_at.present?

  def author = user&.name || author_name || I18n.t("answers.someone")

  private
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
