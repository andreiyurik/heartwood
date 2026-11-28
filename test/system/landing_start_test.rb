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

    assert_selector ".landing-scene__title strong", text: "Род Петровых"
    assert_selector ".landing-scene__title .crest text", text: expected.crest_letter

    find(".landing-start button[type=submit]").click
    assert_field "tree_name", with: "Род Петровых"
  end

  test "the scene rests on its last frame and can be played again" do
    visit root_path
    wait_for_stimulus "scene", ".landing-scene"

    assert_no_selector ".landing-scene--waiting"
    assert_selector ".landing-scene__person--found", style: { opacity: "1" }
    assert_selector ".landing-scene__slot", style: { opacity: "0" }, visible: :all

    find(".landing-scene__replay").click
    assert_selector ".landing-scene--playing .landing-scene__person--found", style: { opacity: "1" }
    assert_selector ".landing-scene__flight", style: { opacity: "1" }
    assert_not_equal "", page.evaluate_script("document.querySelector('.landing-scene').style.getPropertyValue('--fly-x')")
  end
end
