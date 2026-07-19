require "application_system_test_case"

# The add-relative combobox: a debounced search field (search_controller.js) that submits
# into a nested Turbo Frame of candidates, then links the chosen existing person. None of
# the debounce → frame-update → pick chain is provable by server rendering alone.
class RelativesComboboxTest < ApplicationSystemTestCase
  setup do
    @tree     = trees(:alpha)
    @focus    = Person.create!(given_names: "Focus", surname: "Person", sex: "M", tree: @tree)
    @existing = Person.create!(given_names: "Grace", surname: "Hopper", sex: "F", tree: @tree)
    Event.create!(kind: "DEAT", eventable: @existing, tree: @tree)
    sign_in_as users(:one)
  end

  test "finds an existing person via the combobox and links them as a parent" do
    visit person_path(@focus)

    click_link I18n.t("family.add", relation: I18n.t("family.relation_singular.parent"))

    # The add-parent Turbo Frame loads the combobox; wait for its search field, then for
    # its Stimulus controller to connect before typing (otherwise the debounced search
    # never fires and no candidate appears).
    find_field("q", wait: 10)
    wait_for_stimulus("search", "form.combobox")
    fill_in "q", with: "Grace"

    # click_on waits for the candidate button to render in the relative_candidates frame.
    click_on "Grace Hopper", wait: 10    # button_to create with existing_person_id, target _top

    # Back on the profile, Grace is now a LINKED parent — an <a> to her profile, which the
    # combobox candidate (a button) never is, so this can't match the candidate by mistake.
    assert_link "Grace Hopper", href: person_path(@existing), wait: 5
    assert_includes @focus.reload.parents, @existing
  end
end
