require "application_system_test_case"

# Single-key shortcuts (hotkey_controller.js): they must stay out of the way while typing.
class HotkeysTest < ApplicationSystemTestCase
  setup do
    @tree = trees(:alpha)
    @person = Person.create!(given_names: "Ada", surname: "Lovelace", sex: "F", tree: @tree)
    sign_in_as users(:one)
  end

  test "slash focuses the search box and n opens the add-person form" do
    visit people_path
    wait_for_stimulus("hotkey", "[data-controller~=hotkey]")

    find("body").send_keys("/")
    assert_equal "q", page.evaluate_script("document.activeElement.name")

    find("input[name=q]").send_keys("n")
    assert_current_path people_path, ignore_query: true
    assert_equal "q", page.evaluate_script("document.activeElement.name"), "typing in a field must not trigger shortcuts"

    find("h1").click
    find("body").send_keys("n")
    assert_current_path new_person_path, wait: 10
  end

  test "e edits the person you are looking at" do
    visit person_path(@person)
    wait_for_stimulus("hotkey", "[data-controller~=hotkey]")
    find("body").send_keys("e")
    assert_current_path edit_person_path(@person), wait: 10
  end
end
