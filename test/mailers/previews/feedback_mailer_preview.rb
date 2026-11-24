class FeedbackMailerPreview < ActionMailer::Preview
  def sent
    FeedbackMailer.with(user: User.first, body: "Не нашёл, как добавить сестру бабушки.", page: "/people/1", locale: "ru").sent
  end
end
