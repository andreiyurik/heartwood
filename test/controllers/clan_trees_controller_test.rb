require "test_helper"

class ClanTreesControllerTest < ActionDispatch::IntegrationTest
  test "GET show renders the родовое древо rooted at the progenitor" do
    sign_in_as users(:bach)
    get clan_tree_url
    assert_response :success
    assert_select "[data-tree-mode-value='descendants']"
    assert_select ".tree-node--focus[data-tree-node-id='#{people(:ambrosius).id}']"
  end

  test "GET show embeds graph JSON with unions" do
    sign_in_as users(:bach)
    get clan_tree_url
    assert_select "[data-tree-graph-value*='unions']"
  end

  test "GET show shows an empty state for a tree with no people" do
    sign_in_as users(:one)
    get clan_tree_url
    assert_response :success
    assert_select ".tree-canvas", count: 0
    assert_select ".blank-slate"
  end

  test "GET show requires authentication" do
    sign_out
    get clan_tree_url
    assert_redirected_to new_session_url
  end
end
