require "test_helper"

class ShareLinksControllerTest < ActionDispatch::IntegrationTest
  setup do
    @tree = trees(:bach)
    sign_in_as users(:bach)
  end

  test "the owner turns the view link on, sees it on the members page, renews and turns it off" do
    post share_link_url
    assert_redirected_to tree_memberships_url
    first = @tree.reload.share_link.token

    get tree_memberships_url
    assert_select "input[value=?]", shared_tree_url(first)

    post share_link_url
    assert_not_equal first, @tree.reload.share_link.token

    delete share_link_url
    assert_nil @tree.reload.share_link
  end

  test "an editor can't share the tree" do
    TreeMembership.create!(user: users(:one), tree: @tree, role: "editor")
    sign_out
    sign_in_as users(:one)
    patch active_tree_url, params: { tree_id: @tree.id }

    post share_link_url
    assert_response :forbidden
    assert_nil @tree.reload.share_link
  end
end
