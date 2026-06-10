require "test_helper"

class TreesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @person = Person.create!(given_names: "Johann Sebastian", surname: "Bach", sex: "M")
    sign_in_as users(:one)
  end

  test "GET show renders the ancestors tree by default" do
    get person_tree_url(@person)
    assert_response :success
    assert_select "title", /Bach/
  end

  test "GET show with mode=descendants renders descendants" do
    get person_tree_url(@person, mode: "descendants")
    assert_response :success
    assert_select "[data-tree-mode-value='descendants']"
  end

  test "GET show with mode=ancestors renders ancestors" do
    get person_tree_url(@person, mode: "ancestors")
    assert_response :success
    assert_select "[data-tree-mode-value='ancestors']"
  end

  test "GET show requires authentication" do
    sign_out
    get person_tree_url(@person)
    assert_redirected_to new_session_url
  end

  test "GET show embeds graph JSON on the page" do
    get person_tree_url(@person)
    assert_select "[data-tree-graph-value]"
  end

  test "GET show renders a node for the focus person" do
    get person_tree_url(@person)
    assert_select ".tree-node", minimum: 1
  end

  test "GET show with depth param limits the graph depth" do
    parent = Person.create!(sex: "M")
    fam = Family.create!
    fam.partners << parent
    fam.children << @person

    get person_tree_url(@person, depth: 0)
    # depth 0 → only focus person in graph JSON (checked via node count in DOM)
    assert_select ".tree-node", count: 1

    get person_tree_url(@person, depth: 1)
    assert_select ".tree-node", count: 2
  end
end
