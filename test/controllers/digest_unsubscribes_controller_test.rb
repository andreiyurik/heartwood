require "test_helper"

class DigestUnsubscribesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user  = users(:one)
    @token = @user.generate_token_for(:digest_unsubscribe)
  end

  test "the link opens a page with one button, and a mail scanner's GET changes nothing" do
    get digest_unsubscribe_url(@token)
    assert_response :success
    assert_select "form[action=?] button, form[action=?] input[type=submit]", digest_unsubscribe_path(@token), digest_unsubscribe_path(@token)
    assert @user.reload.weekly_digest?
  end

  test "pressing it, or a mail client's one-click POST, switches the digest off without signing in" do
    post digest_unsubscribe_url(@token)
    assert_not @user.reload.weekly_digest?
    assert_response :redirect
  end

  test "a broken token does nothing" do
    post digest_unsubscribe_url("nope")
    assert_response :not_found
  end

  test "the account page switches it back on" do
    @user.update!(weekly_digest: false)
    sign_in_as @user

    get account_url
    assert_select "input[type=checkbox][name='user[weekly_digest]']"

    patch account_url, params: { user: { weekly_digest: "1" } }
    assert @user.reload.weekly_digest?
  end

  test "switching locale remembers it for the letters" do
    sign_in_as @user
    patch locale_url, params: { locale: "ru" }
    assert_equal "ru", @user.reload.locale
  end
end
