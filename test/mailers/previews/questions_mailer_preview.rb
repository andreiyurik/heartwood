class QuestionsMailerPreview < ActionMailer::Preview
  def answered
    QuestionsMailer.answered(Answer.last)
  end
end
