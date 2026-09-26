require "test_helper"

class TreesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @tree   = trees(:bach)
    @person = people(:johann_sebastian)
    sign_in_as users(:bach)
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

  test "node renders the name on two lines: given names over surname" do
    get person_tree_url(@person)
    assert_select ".tree-node--focus .node-name",    text: "Johann Sebastian"
    assert_select ".tree-node--focus .node-surname", text: "Bach"
  end

  test "GET show with depth param limits the graph depth" do
    get person_tree_url(@person, depth: 0)
    assert_select ".tree-node", count: 1

    get person_tree_url(@person, depth: 1)
    assert_select ".tree-node", count: 3
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
    assert_select "span.btn[aria-disabled='true']", text: "−"
  end

  test "depth control plus is disabled at maximum depth" do
    get person_tree_url(@person, depth: 6)
    assert_select "span.btn[aria-disabled='true']", text: "+"
  end

  test "node link loads the person panel into the drawer frame" do
    get person_tree_url(@person, depth: 1)
    assert_select ".tree-node:not(.tree-node--focus) a[href*='/panel'][data-turbo-frame='person-panel']"
  end

  test "descendants view renders the married-in spouse as a couple" do
    get person_tree_url(@person, mode: "descendants", depth: 1)
    wives = [ people(:maria_barbara), people(:anna_magdalena) ].map { |wife| ".tree-node[data-tree-node-id='#{wife.id}']" }
    assert_select wives.join(", "), minimum: 1
    assert_select "[data-tree-graph-value*='unions']"
  end

  test "a node without a photo renders an outline silhouette, not initials" do
    get person_tree_url(@person)
    assert_select ".tree-node--focus .node-avatar--silhouette svg"
  end

  test "renders an add-parent ghost slot for an ancestor without parents" do
    get person_tree_url(@person)   # Bach has no parents recorded
    assert_select ".tree-node--ghost a[href*='/relatives/new'][href*='relation=parent']"
  end

  test "non-focus nodes link to their panel card" do
    get person_tree_url(@person, mode: "descendants", depth: 1)
    assert_select ".tree-node:not(.tree-node--focus) a[href*='/panel']"
  end
end
