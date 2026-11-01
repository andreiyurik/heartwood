require "application_system_test_case"

class EditHistoryTest < ApplicationSystemTestCase
  setup do
    @person = people(:johann_sebastian)
    sign_in_as users(:bach)
  end

  test "a person deleted by mistake comes back with one click in the flash" do
    delete_person

    within(".flash") { click_on I18n.t("edits.undo") }

    visit person_path(@person)
    assert_selector "h1", text: "Johann Sebastian Bach"
    assert_text "Birth"
  end

  test "the history page restores a deleted person" do
    delete_person

    visit edits_path
    within(".edit-row", text: "Johann Sebastian Bach") { click_on I18n.t("edits.restore") }

    assert_selector ".edit-row--reverted", text: "Johann Sebastian Bach"
    visit people_path
    assert_text "Johann Sebastian Bach"
  end

  private
    def delete_person
      visit person_path(@person)
      find("summary[title='#{I18n.t("people.more")}']").click
      accept_confirm { click_on I18n.t("people.delete_person") }
      assert_selector "h1", text: I18n.t("people.title")
    end
end
