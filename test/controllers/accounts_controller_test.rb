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
end
