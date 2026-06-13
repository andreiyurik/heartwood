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

    # The add-parent Turbo Frame loads the combobox; wait for its search field.
    field = find_field("q", wait: 10)
    field.set("Grace")
    # Nudge one more input AFTER the frame has settled, in case the Stimulus search
    # controller connected just after the first keystrokes (otherwise the debounce that
    # submits the search never fires and no candidate appears).
    field.send_keys(" ", :backspace)

    # click_on waits for the candidate button to render in the relative_candidates frame.
    click_on "Grace Hopper", wait: 10    # button_to create with existing_person_id, target _top

    # Back on the profile, Grace is now a LINKED parent — an <a> to her profile, which the
    # combobox candidate (a button) never is, so this can't match the candidate by mistake.
    assert_link "Grace Hopper", href: person_path(@existing), wait: 5
    assert_includes @focus.reload.parents, @existing
  end
end
