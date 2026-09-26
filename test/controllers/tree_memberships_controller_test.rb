require "test_helper"

# The members page: visible to everyone in the tree, role changes and removal
# are owner-only. See [[collaboration]].
class TreeMembershipsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @tree = trees(:alpha)
    @owner = users(:one)
    @editor_user = User.create!(name: "Editor Guy", email_address: "editor@example.com", password: "password")
    @membership = TreeMembership.create!(user: @editor_user, tree: @tree, role: "editor")
  end

  test "any member can view the members page" do
    post session_url, params: { email_address: @editor_user.email_address, password: "password" }
    get tree_memberships_url
    assert_response :success
    assert_match(@editor_user.name, @response.body)
  end

  test "the invite box copies the join link and labels it" do
    post session_url, params: { email_address: @owner.email_address, password: "password" }
    get tree_memberships_url

    assert_select "button[data-controller=copy-to-clipboard][data-copy-to-clipboard-content-value=?]", join_url(@tree.join_code)
    assert_select "input[readonly][aria-labelledby=invite_label][value=?]", join_url(@tree.join_code)
    assert_select "#invite_label", text: I18n.t("tree_memberships.invite_label")
  end

  test "owner sees the invite box, non-owner does not" do
    post session_url, params: { email_address: @owner.email_address, password: "password" }
    get tree_memberships_url
    assert_select ".invite-box"

    delete session_url
    post session_url, params: { email_address: @editor_user.email_address, password: "password" }
    get tree_memberships_url
    assert_select ".invite-box", count: 0
  end

  test "owner can change a member's role" do
    post session_url, params: { email_address: @owner.email_address, password: "password" }
    patch tree_membership_url(@membership), params: { tree_membership: { role: "viewer" } }
    assert_redirected_to tree_memberships_url
    assert_equal "viewer", @membership.reload.role
  end

  test "owner can remove a member" do
    post session_url, params: { email_address: @owner.email_address, password: "password" }
    assert_difference "TreeMembership.count", -1 do
      delete tree_membership_url(@membership)
    end
  end

  test "non-owner cannot change roles or remove members" do
    post session_url, params: { email_address: @editor_user.email_address, password: "password" }

    patch tree_membership_url(@membership), params: { tree_membership: { role: "viewer" } }
    assert_redirected_to root_url
    assert_equal "editor", @membership.reload.role

    assert_no_difference "TreeMembership.count" do
      delete tree_membership_url(@membership)
    end
  end

  test "the owner row can't be demoted or removed even by the owner" do
    post session_url, params: { email_address: @owner.email_address, password: "password" }
    owner_membership = @tree.tree_memberships.find_by(role: "owner")

    patch tree_membership_url(owner_membership), params: { tree_membership: { role: "viewer" } }
    assert_response :forbidden
    assert_equal "owner", owner_membership.reload.role

    delete tree_membership_url(owner_membership)
    assert_response :forbidden
    assert TreeMembership.exists?(owner_membership.id)
  end

  test "role param is whitelisted to editor/viewer — can't sneak in a second owner" do
    @membership.update!(role: "viewer")
    post session_url, params: { email_address: @owner.email_address, password: "password" }
    patch tree_membership_url(@membership), params: { tree_membership: { role: "owner" } }
    assert_equal "editor", @membership.reload.role # invalid value falls back, doesn't become owner
  end
end
