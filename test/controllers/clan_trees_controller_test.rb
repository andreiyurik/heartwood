require "test_helper"

class ClanTreesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @tree = trees(:alpha)
    sign_in_as users(:one)
    Current.tree = @tree
  end

  test "GET show renders the родовое древо rooted at the progenitor" do
    founder = Person.create!(given_names: "Founder", surname: "Clan", sex: "M", tree: @tree)
    child   = Person.create!(given_names: "Kid",     surname: "Clan", sex: "F", tree: @tree)
    fam = Family.create!(tree: @tree)
    fam.partners << founder
    fam.children << child

    get clan_tree_url
    assert_response :success
    assert_select "[data-tree-mode-value='descendants']"
    # The founder is the highlighted focus of the whole-clan view.
    assert_select ".tree-node--focus[data-tree-node-id='#{founder.id}']"
  end

  test "GET show embeds graph JSON with unions" do
    a = Person.create!(given_names: "A", sex: "M", tree: @tree)
    b = Person.create!(given_names: "B", sex: "F", tree: @tree)
    kid = Person.create!(given_names: "Kid", sex: "U", tree: @tree)
    fam = Family.create!(tree: @tree)
    fam.partners << a << b
    fam.children << kid

    get clan_tree_url
    assert_select "[data-tree-graph-value*='unions']"
  end

  test "GET show shows an empty state for a tree with no people" do
    get clan_tree_url
    assert_response :success
    assert_select ".tree-canvas", count: 0
    assert_select "p.empty"
  end

  test "GET show requires authentication" do
    sign_out
    get clan_tree_url
    assert_redirected_to new_session_url
  end
end
