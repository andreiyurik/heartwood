require "test_helper"

class TreesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @tree   = trees(:alpha)
    @person = Person.create!(given_names: "Johann Sebastian", surname: "Bach", sex: "M", tree: @tree)
    sign_in_as users(:one)
    Current.tree = @tree
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
    parent = Person.create!(sex: "M", tree: @tree)
    fam = Family.create!(tree: @tree)
    fam.partners << parent
    fam.children << @person

    get person_tree_url(@person, depth: 0)
    # depth 0 → only focus person in graph JSON (checked via node count in DOM)
    assert_select ".tree-node", count: 1

    get person_tree_url(@person, depth: 1)
    assert_select ".tree-node", count: 2
  end

  test "mode toggle links preserve current depth" do
    get person_tree_url(@person, mode: "ancestors", depth: 3)
    # The descendants button should carry depth=3
    assert_select "a[href*='mode=descendants'][href*='depth=3']"
  end

  test "depth controls link to incremented and decremented depth" do
    get person_tree_url(@person, mode: "ancestors", depth: 3)
    assert_select "a[href*='depth=2']"
    assert_select "a[href*='depth=4']"
  end

  test "depth control minus is disabled at minimum depth" do
    get person_tree_url(@person, depth: 1)
    assert_select "span.button--disabled", text: "−"
  end

  test "depth control plus is disabled at maximum depth" do
    get person_tree_url(@person, depth: 6)
    assert_select "span.button--disabled", text: "+"
  end

  test "node link goes to tree path for refocus (not profile)" do
    parent = Person.create!(sex: "M", tree: @tree)
    fam = Family.create!(tree: @tree)
    fam.partners << parent
    fam.children << @person

    get person_tree_url(@person, depth: 1)
    # Each visible non-focus node should link to person_tree_path, not person_path
    assert_select ".tree-node:not(.tree-node--focus) a[href*='/tree']"
  end

  test "descendants view renders the married-in spouse as a couple" do
    spouse = Person.create!(given_names: "Spouse", surname: "Married", sex: "F", tree: @tree)
    child  = Person.create!(given_names: "Kid",    surname: "Bach",    sex: "M", tree: @tree)
    fam = Family.create!(tree: @tree)
    fam.partners << @person << spouse   # spouse married in — not a blood descendant
    fam.children << child

    get person_tree_url(@person, mode: "descendants", depth: 1)
    # The spouse has no blood-descendant path, but the couple model surfaces them.
    assert_select ".tree-node[data-tree-node-id='#{spouse.id}']"
    assert_select "[data-tree-graph-value*='unions']"
  end

  test "non-focus nodes link to that person's tree for refocus" do
    child = Person.create!(sex: "F", tree: @tree)
    fam = Family.create!(tree: @tree)
    fam.partners << @person
    fam.children << child

    get person_tree_url(@person, mode: "descendants", depth: 1)
    # Child node must link to the child's tree path (refocus), not their profile
    assert_select ".tree-node:not(.tree-node--focus) a[href*='/tree']"
  end
end
