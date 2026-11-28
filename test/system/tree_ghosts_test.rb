require "application_system_test_case"

# Ghost add-relative slots: dashed placeholder nodes at the tree's growth frontier.
# Clicking one loads the add-relative form into the slide-over panel; submitting
# returns to the tree with the new person in the graph. The full round-trip only
# exists in a real browser (turbo-frame into drawer, form targeting _top).
class TreeGhostsTest < ApplicationSystemTestCase
  setup do
    @tree   = trees(:alpha)
    @focus  = Person.create!(given_names: "Focus", surname: "Person", sex: "M", tree: @tree)
    @mother = Person.create!(given_names: "Mona",  surname: "Parent", sex: "F", tree: @tree)
    Event.create!(kind: "DEAT", eventable: @focus,  tree: @tree)
    Event.create!(kind: "DEAT", eventable: @mother, tree: @tree)

    family = Family.create!(tree: @tree)
    family.children << @focus
    family.partners << @mother

    sign_in_as users(:one)
  end

  test "adding a parent through a ghost slot returns to the tree with the new person" do
    visit person_tree_path(@focus, depth: 2)
    assert_selector ".tree-edges path", wait: 5

    # The mother has no parents recorded → a dashed add-parent slot sits above her.
    ghost = find(".tree-node--ghost a")
    page.execute_script("arguments[0].click()", ghost)

    assert_selector ".tree-drawer--open", wait: 5
    within ".tree-drawer" do
      fill_in "person[given_names]", with: "Greta"
      fill_in "person[surname]",     with: "Parent"
      find("label.choice", text: I18n.t("people.sex.F"), exact_text: true).click
      click_on I18n.t("people.add")
    end

    # Back on the tree page, with Greta now rendered as the mother's parent.
    assert_current_path person_tree_path(@focus), ignore_query: true, wait: 5
    assert_selector ".tree-node .node-name", text: "Greta", wait: 5
  end
end
