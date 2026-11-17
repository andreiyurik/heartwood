class QuestionsMailer < ApplicationMailer
  def answered(answer)
    @answer, @question = answer, answer.question
    @asker = @question.asker
    @unsubscribe_url = letter_unsubscribe_url("answers", @asker.unsubscribe_token("answers"))

    headers "List-Unsubscribe" => "<#{@unsubscribe_url}>", "List-Unsubscribe-Post" => "List-Unsubscribe=One-Click"

    I18n.with_locale(@asker.locale.presence || I18n.default_locale) do
      mail to: @asker.email_address, subject: t("questions_mailer.answered.subject", question: @question.body.truncate(60))
    end
  end
end
