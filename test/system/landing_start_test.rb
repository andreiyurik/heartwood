require "application_system_test_case"

# docs/features/landing.md "Hero": the crest drawn as the family's name is typed is the one the tree gets.
class LandingStartTest < ApplicationSystemTestCase
  test "typing the family's name draws its crest, and starting carries the name into sign-up" do
    visit root_path
    fill_in "tree_name", with: "Род Петровых"

    expected = Tree.new(name: "Род Петровых")
    assert_selector ".landing-start .crest text", text: expected.crest_letter
    assert_equal expected.crest_hue_value.to_s,
      page.evaluate_script("document.querySelector('.landing-start .crest').style.getPropertyValue('--avatar-hue').trim()")

    find(".landing-start button[type=submit]").click
    assert_field "tree_name", with: "Род Петровых"
  end
end
