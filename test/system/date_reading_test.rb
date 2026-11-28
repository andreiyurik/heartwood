require "application_system_test_case"

# docs/domain/event.md "Typing a date"
class DateReadingTest < ApplicationSystemTestCase
  test "a typed date is read back under the field, and Old Style is one click" do
    sign_in_as users(:one)
    visit new_person_path

    fill_in "person_born", with: "12.03.1901"
    assert_selector "#person_born_reading .date-reading__date", text: I18n.l(Date.new(1901, 3, 12), format: "%-d %B %-Y")

    click_on I18n.t("date_readings.old_style")
    assert_field "person_born", with: "12.03.1901 #{I18n.t("date_readings.old_style_suffix")}"
    assert_selector "#person_born_reading", text: I18n.l(Date.new(1901, 3, 25), format: "%-d %B %-Y")

    fill_in "person_born", with: ""
    assert_no_selector "#person_born_reading .date-reading"
  end
end
