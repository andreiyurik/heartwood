require "test_helper"

class AccountsControllerTest < ActionDispatch::IntegrationTest
  include ActiveJob::TestHelper

  setup do
    @user = users(:bach)
    sign_in_as @user
  end

  test "requires authentication" do
    sign_out
    get account_url
    assert_redirected_to new_session_url
  end

  test "shows who you are, an export, and how much deleting would take with it" do
    TreeMembership.create!(user: users(:one), tree: trees(:bach), role: "editor")

    get account_url
    assert_response :success
    assert_match @user.email_address, response.body
    assert_select "form[action=?]", export_path
    assert_select "form[action=?][method=post] input[name=_method][value=delete]", account_path
    assert_match "Bach family", response.body
  end

  test "deleting needs the password" do
    delete account_url, params: { password: "wrong" }
    assert_response :unprocessable_entity
    assert User.exists?(@user.id)
  end

  test "deleting with the password removes the account and its trees and signs out" do
    tree = trees(:bach)
    perform_enqueued_jobs do
      delete account_url, params: { password: "password" }
    end

    assert_redirected_to new_session_url
    assert_not User.exists?(@user.id)
    assert_not Tree.exists?(tree.id)

    get people_url
    assert_redirected_to new_session_url
  end

  test "history keeps edits by a deleted person, without their name" do
    Current.set(session: users(:one).sessions.create!, tree: trees(:alpha)) { Person.create!(given_names: "Kept", sex: "U") }
    users(:one).destroy!
    sign_out
    sign_in_as users(:two)
    TreeMembership.create!(user: users(:two), tree: trees(:alpha), role: "editor")
    Session.last.update!(current_tree: trees(:alpha))

    get edits_url
    assert_select ".edit-row", text: /#{I18n.t("edits.deleted_user")}/
  end

  test "you can change your name without typing a password" do
    patch account_url, params: { user: { name: "J. S. Bach", email_address: @user.email_address } }
    assert_redirected_to account_url
    assert_equal "J. S. Bach", @user.reload.name
  end

  test "a new email or password needs the current password" do
    patch account_url, params: { user: { name: @user.name, email_address: "new@example.com", password: "new-password-1" } }
    assert_response :unprocessable_entity
    assert_equal "bach@example.com", @user.reload.email_address

    patch account_url, params: { user: { name: @user.name, email_address: "new@example.com", password: "new-password-1", password_challenge: "password" } }
    assert_redirected_to account_url
    assert_equal "new@example.com", @user.reload.email_address
    assert @user.authenticate("new-password-1")
  end

  test "a blank new password leaves the old one in place" do
    patch account_url, params: { user: { name: "Johann", email_address: @user.email_address, password: "" } }
    assert @user.reload.authenticate("password")
  end

  test "changing the password signs out your other devices" do
    other = @user.sessions.create!
    patch account_url, params: { user: { name: @user.name, email_address: @user.email_address, password: "new-password-1", password_challenge: "password" } }
    assert_not Session.exists?(other.id)
    get account_url
    assert_response :success
  end
end
