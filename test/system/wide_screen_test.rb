require "application_system_test_case"

# Text pages keep the reading width; the tree and the map are a workspace and take the window.
class WideScreenTest < ApplicationSystemTestCase
  setup do
    tree = trees(:alpha)
    parent, child = %w[Parent Child].map { Person.create!(given_names: it, surname: "Wide", sex: "M", tree: tree) }
    Family.create!(tree: tree).tap { it.partners << parent; it.children << child }
    sign_in_as users(:one)
  end

  test "on a wide screen the tree takes the window, and its search keeps a reading width" do
    visit clan_tree_path
    window = page.evaluate_script("window.innerWidth")

    assert_operator sheet_width, :>=, window - 64
    assert_operator page.evaluate_script("document.querySelector('.tree-search').getBoundingClientRect().width"), :<=, 32 * 16
  end

  test "text pages keep the sheet's reading width" do
    visit people_path
    assert_equal 68 * 16, sheet_width
  end

  private
    def sheet_width = page.evaluate_script("Math.round(document.querySelector('#main').getBoundingClientRect().width)")
end
