require "test_helper"

class PasswordsMailerTest < ActionMailer::TestCase
  test "the reset letter goes to the user with a working link, in their language" do
    user = users(:one)
    mail = PasswordsMailer.with(locale: :ru).reset(user)

    assert_equal [ user.email_address ], mail.to
    assert_equal I18n.t("mailer.password_reset.subject", locale: :ru), mail.subject
    assert_match %r{/passwords/\S+/edit}, mail.text_part.decoded
    assert_includes mail.text_part.decoded, "15 минут"
  end
end
