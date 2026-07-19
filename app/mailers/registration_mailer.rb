class RegistrationMailer < ApplicationMailer
  # Sent right after sign-up: a warm, personal hello plus a nudge toward the first
  # meaningful action (add a person or import a GEDCOM).
  def welcome(user)
    @user   = user
    @locale = params&.dig(:locale) || I18n.default_locale
    I18n.with_locale(@locale) do
      mail subject: t("mailer.welcome.subject"), to: user.email_address
    end
  end
end
