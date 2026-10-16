require "application_system_test_case"

class ReducedMotionTest < ApplicationSystemTestCase
  test "the browser under test asks for reduced motion, so clicks land on resting elements" do
    visit new_session_path

    assert page.evaluate_script("matchMedia('(prefers-reduced-motion: reduce)').matches")
    assert_equal "auto", page.evaluate_script("getComputedStyle(document.documentElement).scrollBehavior")
  end
end
