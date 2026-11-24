require "test_helper"

class SessionsControllerTest < ActionDispatch::IntegrationTest
  setup { @user = User.take }

  test "new is one panel: the mark leading home, a welcome, the form, and the way to forgotten passwords beside the password" do
    get new_session_path
    assert_response :success
    assert_select ".auth-card .auth-mark[href=?] svg.logo", root_path
    assert_select ".auth-card h1", I18n.t("auth.welcome_title")
    assert_select ".auth-card .auth-form a[href=?]", new_password_path
    assert_select ".auth-wrap > .auth-alt a[href=?]", new_registration_path
  end

  test "create with valid credentials" do
    post session_path, params: { email_address: @user.email_address, password: "password" }

    assert_redirected_to root_path
    assert cookies[:session_id]
  end

  test "create with invalid credentials" do
    post session_path, params: { email_address: @user.email_address, password: "wrong" }

    assert_redirected_to new_session_path(email_address: @user.email_address)
    assert_nil cookies[:session_id]
  end

  test "destroy" do
    sign_in_as(User.take)

    delete session_path

    assert_redirected_to new_session_path
    assert_empty cookies[:session_id]
  end

  test "a failed sign-in shakes the card, marks the fields and keeps the email" do
    post session_path, params: { email_address: "one@example.com", password: "wrong" }
    follow_redirect!

    assert_select ".auth-card.shake"
    assert_select "input[name=email_address][value=?][aria-invalid=true]", "one@example.com"
    assert_select "input[name=password][aria-invalid=true]"
  end

  test "a fresh sign-in page does not shake" do
    get new_session_path
    assert_select ".shake", count: 0
    assert_select "[aria-invalid]", count: 0
  end

  test "a wrong password is explained next to the form, not in a toast across the screen" do
    post session_path, params: { email_address: "one@example.com", password: "wrong" }
    follow_redirect!
    assert_select ".auth-form .auth-error[role=alert]", text: I18n.t("flash.invalid_credentials")
    assert_select ".flash", count: 0
  end
end
