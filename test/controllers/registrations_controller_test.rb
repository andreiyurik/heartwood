require "test_helper"

# Open sign-up: create an account, get signed in immediately, and own a fresh tree.
# Styled after fizzy's signup, but password-based to fit Heartwood's self-host auth.
class RegistrationsControllerTest < ActionDispatch::IntegrationTest
  test "new renders the sign-up form without requiring authentication" do
    get new_registration_path
    assert_response :success
    assert_select "form"
    assert_select "input[name='user[name]']"
    assert_select "input[name='user[email_address]']"
    assert_select "input[name='user[password]']"
  end

  test "create registers a user, signs them in, and bootstraps their owner tree" do
    assert_difference "User.count", 1 do
      post registration_path, params: { user: {
        name: "Ada Lovelace", email_address: "ada@example.com", password: "secret123" } }
    end

    assert_redirected_to root_path
    assert cookies[:session_id].present?, "the new user should be signed in"

    user = User.find_by(email_address: "ada@example.com")
    assert_equal "Ada Lovelace", user.name

    follow_redirect!  # first authenticated request bootstraps the tree
    assert_response :success
    assert user.reload.trees.exists?, "a tree should be bootstrapped for the new owner"
  end

  test "create sends a welcome email" do
    assert_enqueued_emails 1 do
      post registration_path, params: { user: {
        name: "Grace Hopper", email_address: "grace@example.com", password: "secret123" } }
    end
  end

  test "create with invalid params re-renders the form (422) and creates nothing" do
    assert_no_difference "User.count" do
      post registration_path, params: { user: {
        name: "", email_address: "not-an-email", password: "short" } }
    end
    assert_response :unprocessable_entity
  end

  test "create rejects a duplicate email address gracefully" do
    assert_no_difference "User.count" do
      post registration_path, params: { user: {
        name: "Impostor", email_address: users(:one).email_address, password: "secret123" } }
    end
    assert_response :unprocessable_entity
  end
end
