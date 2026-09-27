require "application_system_test_case"

# The family-tree canvas (app/javascript/controllers/tree_controller.js) is the one piece
# of hand-written JS in the app. Clicking a node opens the slide-over person panel
# (drawer_controller.js + a turbo-frame); refocusing the tree happens from the panel.
# Server rendering can't prove either, so this drives them in a real browser.
class TreeNavigationTest < ApplicationSystemTestCase
  setup do
    @tree   = trees(:alpha)
    @focus  = Person.create!(given_names: "Focus", surname: "Person", sex: "M", tree: @tree)
    @parent = Person.create!(given_names: "Pat",   surname: "Parent", sex: "F", tree: @tree)
    # Both deceased so nodes render with names + links (living nodes are redacted/linkless).
    Event.create!(kind: "DEAT", eventable: @focus,  tree: @tree)
    Event.create!(kind: "DEAT", eventable: @parent, tree: @tree)

    family = Family.create!(tree: @tree)
    family.children << @focus
    family.partners << @parent

    sign_in_as users(:one)
  end

  test "clicking a node opens the person panel; its tree button refocuses" do
    visit person_tree_path(@focus)
    assert_selector ".tree-node--focus .node-name", text: "Focus"

    # Wait for the Stimulus controller to lay out nodes and draw edges before clicking —
    # before layout, every node is stacked at (0,0) and overlaps the focus node.
    assert_selector ".tree-edges path", wait: 5

    # The canvas applies pan/zoom transforms, so a geometric click can land on an
    # overlapping node; dispatching the click on the exact rendered anchor keeps the
    # test deterministic while still exercising the real turbo-frame load.
    link = find("[data-tree-node-id='#{@parent.id}'] a")
    page.execute_script("arguments[0].click()", link)

    assert_selector ".tree-drawer--open", wait: 5
    assert_selector ".person-panel-name", text: "Pat Parent"

    # The panel's tree button re-centres the whole page on that person.
    find(".person-panel-actions a[href*='/tree']").click
    assert_current_path person_tree_path(@parent), ignore_query: true
    assert_selector ".tree-node--focus .node-name", text: "Pat"
  end

  test "arrow keys walk to a relative and Enter opens their panel" do
    visit person_tree_path(@focus)
    assert_selector ".tree-edges path", wait: 5

    page.execute_script("document.querySelector('.tree-canvas').focus()")
    canvas = find(".tree-canvas")
    canvas.send_keys :arrow_up   # ancestors mode: up goes to the parent above
    assert_selector ".tree-node--kb .node-name", text: "Pat"

    canvas.send_keys :enter
    assert_selector ".tree-drawer--open", wait: 5
    assert_selector ".person-panel-name", text: "Pat Parent"
  end

  test "closing the panel empties the frame so the same person can be reopened" do
    visit person_tree_path(@focus)
    assert_selector ".tree-edges path", wait: 5

    link = find("[data-tree-node-id='#{@parent.id}'] a")
    page.execute_script("arguments[0].click()", link)
    assert_selector ".tree-drawer--open", wait: 5

    find(".person-panel-close").click
    assert_no_selector ".tree-drawer--open"
    assert_no_selector ".person-panel-name"

    page.execute_script("arguments[0].click()", link)
    assert_selector ".tree-drawer--open", wait: 5
    assert_selector ".person-panel-name", text: "Pat Parent"
  end

  test "a long name in the header wraps by word instead of collapsing into a letter column" do
    @focus.update!(given_names: "Григорий Александрович", surname: "Пушкин-Долгорукий")

    window = page.driver.browser.manage.window
    window.resize_to(700, 800)
    begin
      visit person_tree_path(@focus)
      assert_selector ".tree-edges path", wait: 5

      # overflow-wrap: anywhere lets a flex item's automatic minimum size shrink to a
      # single character, so a name this long can collapse into a tall one-letter-per-line
      # column instead of wrapping by word — the header should stay a couple of lines tall.
      header_height = page.evaluate_script("document.getElementById('header').getBoundingClientRect().height")
      assert_operator header_height, :<, 200,
        "expected the header to wrap the name by word, not collapse into a letter column (was #{header_height}px tall)"
    ensure
      window.resize_to(1400, 1400)
    end
  end
end
