# Preview all emails at http://localhost:3000/rails/mailers/registration_mailer
class RegistrationMailerPreview < ActionMailer::Preview
  # Preview this email at http://localhost:3000/rails/mailers/registration_mailer/welcome
  def welcome
    RegistrationMailer.with(locale: I18n.locale).welcome(User.take)
  end
end
