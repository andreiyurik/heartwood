require "application_system_test_case"

# docs/architecture/design-system.md "Theme"
class ThemeTest < ApplicationSystemTestCase
  test "the header button flips the theme, remembers it, and returns to the system one" do
    visit root_path
    assert_no_selector "html[data-theme]"
    surface = -> { page.evaluate_script("getComputedStyle(document.body).backgroundColor") }
    light = surface.call

    find("#header [data-controller=theme]").click
    assert_selector "html[data-theme=dark]"
    assert_not_equal light, surface.call

    visit root_path
    assert_selector "html[data-theme=dark]"
    assert_selector ".landing-window img.only-dark", visible: :all, minimum: 1
    assert_no_selector ".landing-window img.only-light"

    find("#header [data-controller=theme]").click
    assert_no_selector "html[data-theme]"
    visit root_path
    assert_no_selector "html[data-theme]"
  end
end
