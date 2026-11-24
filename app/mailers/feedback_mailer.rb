class FeedbackMailer < ApplicationMailer
  def sent
    @user, @body, @page, @locale = params.values_at(:user, :body, :page, :locale)
    @page_url = root_url.chomp("/") + @page if @page

    mail to: Rails.configuration.x.operator[:email], reply_to: @user.email_address,
         subject: t("feedback_mailer.sent.subject", name: @user.name)
  end
end
