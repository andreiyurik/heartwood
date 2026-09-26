require "test_helper"

class SessionsControllerTest < ActionDispatch::IntegrationTest
  setup { @user = User.take }

  test "new" do
    get new_session_path
    assert_response :success
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
end
