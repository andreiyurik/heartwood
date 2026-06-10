class PasswordsMailer < ApplicationMailer
  def reset(user)
    @user   = user
    @locale = params[:locale] || I18n.default_locale
    I18n.with_locale(@locale) do
      @expiry = distance_of_time_in_words(0, @user.password_reset_token_expires_in)
      mail subject: t("mailer.password_reset.subject"), to: user.email_address
    end
  end
end
