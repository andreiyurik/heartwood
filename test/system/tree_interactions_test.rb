require "application_system_test_case"

# Collapse/expand and search-fly live entirely in tree_controller.js. Server rendering
# can't prove they work, so this drives them in a real browser. Clicks are dispatched
# via JS because geometric clicks inside the canvas pan/zoom transform can miss
# (see TreeNavigationTest for the same lesson).
class TreeInteractionsTest < ApplicationSystemTestCase
  setup do
    @tree = trees(:alpha)

    founder = person("Founder", "M"); fwife = person("Foundress", "F")
    son     = person("Son", "M");     sonw  = person("Son Wife", "F")
    @hidden = person("Gregor Grandson", "M")
    sib     = person("Sibling", "F")

    f0 = Family.create!(tree: @tree); f0.partners << founder << fwife; f0.children << son
    f1 = Family.create!(tree: @tree); f1.partners << son << sonw;      f1.children << [ @hidden, sib ]

    sign_in_as users(:one)
  end

  test "collapsing a branch hides its descendants; search-fly reopens the path" do
    visit clan_tree_path
    assert_selector ".tree-edges path", wait: 5
    assert_selector ".tree-node[data-tree-node-id='#{@hidden.id}']"

    # Collapse the topmost branch — descendants get hidden (display:none).
    js_click first(".tree-toggle")
    assert_selector ".tree-node[data-tree-node-id='#{@hidden.id}'][style*='display: none']",
      visible: :all, wait: 3

    # Search and fly to the hidden person — the path auto-expands and they reappear.
    find(".tree-search-input").set("Gregor")
    assert_selector ".tree-search-results li", text: "Gregor", wait: 3
    js_click find(".tree-search-results li", text: "Gregor")

    node = find(".tree-node[data-tree-node-id='#{@hidden.id}']", visible: :all)
    assert_not node[:style].to_s.include?("display: none"), "flown-to person should be revealed"
  end

  private

  def person(name, sex)
    p = Person.create!(given_names: name, sex: sex, tree: @tree)
    Event.create!(kind: "DEAT", eventable: p, tree: @tree)   # deceased → rendered with name + link
    p
  end

  def js_click(element)
    page.execute_script("arguments[0].click()", element)
    sleep 0.4   # let the Stimulus relayout settle
  end
end
