require "test_helper"

class FeedbackMailerTest < ActionMailer::TestCase
  setup do
    @user = users(:one)
    @original = Rails.configuration.x.operator
    Rails.configuration.x.operator = @original.merge(email: "maker@example.com")
  end

  teardown { Rails.configuration.x.operator = @original }

  test "the letter reaches the operator, is answered by replying, and says who wrote from where" do
    mail = FeedbackMailer.with(user: @user, body: "The tree button does nothing", page: "/people/7?tab=sources", locale: "ru").sent

    assert_equal [ "maker@example.com" ], mail.to
    assert_equal [ @user.email_address ], mail.reply_to
    assert_match @user.name, mail.subject
    body = mail.text_part.body.to_s
    assert_match "The tree button does nothing", body
    assert_match "http://example.com/people/7?tab=sources", body
    assert_match @user.email_address, body
    assert_match "ru", body
  end
end
