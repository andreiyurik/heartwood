require "test_helper"

class LetterUnsubscribesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user  = users(:one)
    @token = @user.unsubscribe_token("digest")
  end

  test "the link opens a page with one button, and a mail scanner's GET changes nothing" do
    get letter_unsubscribe_url("digest", @token)
    assert_response :success
    assert_select "form[action=?] button", letter_unsubscribe_path("digest", @token)
    assert @user.reload.weekly_digest?
  end

  test "pressing it, or a mail client's one-click POST, switches the letters off without signing in" do
    post letter_unsubscribe_url("digest", @token)
    assert_not @user.reload.weekly_digest?
    assert @user.answer_emails?

    post letter_unsubscribe_url("answers", @user.unsubscribe_token("answers"))
    assert_not @user.reload.answer_emails?
  end

  test "a token works only for its own kind of letter" do
    post letter_unsubscribe_url("answers", @token)
    assert_response :not_found
    assert @user.reload.answer_emails?
  end

  test "a broken token or an unknown kind does nothing" do
    post letter_unsubscribe_url("digest", "nope")
    assert_response :not_found
    get "/letters/password/unsubscribe/#{@token}"
    assert_response :not_found
  end

  test "the account page switches each kind back on" do
    @user.update!(weekly_digest: false, answer_emails: false)
    sign_in_as @user

    get account_url
    assert_select "input[type=checkbox][name='user[weekly_digest]']"
    assert_select "input[type=checkbox][name='user[answer_emails]']"

    patch account_url, params: { user: { weekly_digest: "1", answer_emails: "1" } }
    assert @user.reload.weekly_digest?
    assert @user.answer_emails?
  end

  test "switching locale remembers it for the letters" do
    sign_in_as @user
    patch locale_url, params: { locale: "ru" }
    assert_equal "ru", @user.reload.locale
  end
end
