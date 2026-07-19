require "test_helper"

class RegistrationMailerTest < ActionMailer::TestCase
  test "welcome greets the user by name and points them to the first step" do
    user = User.new(name: "Ada Lovelace", email_address: "ada@example.com")
    mail = RegistrationMailer.welcome(user)

    assert_equal [ "ada@example.com" ], mail.to
    assert_match "Heartwood", mail.subject

    body = mail.body.encoded
    assert_match "Ada Lovelace", body                  # personal greeting
    assert_match(/person|tree|GEDCOM/i, body)          # explains what to do next
  end
end
