class RegistrationMailer < ApplicationMailer
  def welcome(user)
    @user   = user
    @locale = params&.dig(:locale) || I18n.default_locale
    I18n.with_locale(@locale) do
      mail subject: t("mailer.welcome.subject"), to: user.email_address
    end
  end
end
