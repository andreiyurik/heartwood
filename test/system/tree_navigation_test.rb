require "application_system_test_case"

# The family-tree canvas (app/javascript/controllers/tree_controller.js) is the one piece
# of hand-written JS in the app. Server rendering can't prove click-to-refocus works; this
# drives it in a real browser.
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

  # Cards render the name on two lines (given over surname), so match the halves
  # rather than the joined display_name.
  test "clicking a parent node refocuses the tree on that person" do
    visit person_tree_path(@focus)
    assert_selector ".tree-node--focus .node-name",    text: "Focus"
    assert_selector ".tree-node--focus .node-surname", text: "Person"

    # Wait for the Stimulus controller to lay out nodes and draw edges before clicking —
    # before layout, every node is stacked at (0,0) and overlaps the focus node.
    assert_selector ".tree-edges path", wait: 5

    # The canvas applies pan/zoom transforms, so a geometric click can land on an
    # overlapping node; dispatching the click on the exact rendered anchor keeps the
    # smoke test deterministic while still exercising the real Turbo refocus navigation.
    link = find("[data-tree-node-id='#{@parent.id}'] a")
    page.execute_script("arguments[0].click()", link)

    assert_current_path person_tree_path(@parent), ignore_query: true
    assert_selector ".tree-node--focus .node-name",    text: "Pat"
    assert_selector ".tree-node--focus .node-surname", text: "Parent"
  end
end
