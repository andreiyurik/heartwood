require "test_helper"

class TreeJoinCodesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @tree = trees(:alpha)
    @editor = User.create!(name: "Editor Guy", email_address: "editor@example.com", password: "password")
    TreeMembership.create!(user: @editor, tree: @tree, role: "editor")
  end

  test "the owner replaces the invite link and the old one stops working" do
    sign_in_as users(:one)
    old = @tree.join_code

    post tree_join_code_url
    assert_redirected_to tree_memberships_url
    assert_not_equal old, @tree.reload.join_code
    get join_url(old)
    assert_response :not_found
  end

  test "an editor cannot replace the invite link" do
    post session_url, params: { email_address: @editor.email_address, password: "password" }
    assert_no_changes -> { @tree.reload.join_code } do
      post tree_join_code_url
    end
    assert_response :forbidden
  end

  test "a visitor is sent to sign in" do
    post tree_join_code_url
    assert_redirected_to new_session_url
  end
end
