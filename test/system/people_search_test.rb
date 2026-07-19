require "application_system_test_case"

# people#index search: a debounced Stimulus input (search_controller.js) that submits the
# form and morphs the results in place. The debounce + morph behavior only exists in the
# browser; the controller test covers the server filter, not the live typing.
class PeopleSearchTest < ApplicationSystemTestCase
  setup do
    @tree = trees(:alpha)
    Person.create!(given_names: "Ada",   surname: "Lovelace", sex: "F", tree: @tree)
    Person.create!(given_names: "Grace", surname: "Hopper",   sex: "F", tree: @tree)
    sign_in_as users(:one)
  end

  test "typing in the search box filters the list live without a full reload" do
    visit people_path
    assert_text "Ada Lovelace"
    assert_text "Grace Hopper"

    # Ensure the search controller is connected before typing, so the debounced submit
    # (→ Turbo morph) reliably fires under headless-browser timing.
    wait_for_stimulus("search", "form.search-form")
    fill_in "q", with: "Grace"

    assert_text "Grace Hopper", wait: 10
    assert_no_text "Ada Lovelace", wait: 10
  end
end
