require "application_system_test_case"

# docs/features/person-profile.md "The add-person form"
class SexGuessTest < ApplicationSystemTestCase
  setup do
    sign_in_as users(:one)
    visit new_person_path
  end

  test "the patronymic or the surname picks the sex until the person picks it themself" do
    fill_in "person_given_names", with: "Алексей Петрович"
    assert_selector "input[name='person[sex]'][value=M]:checked", visible: :all

    fill_in "person_given_names", with: "Анна Петровна"
    assert_selector "input[name='person[sex]'][value=F]:checked", visible: :all

    fill_in "person_given_names", with: "Саша"
    fill_in "person_surname", with: "Кузнецова"
    assert_selector "input[name='person[sex]'][value=F]:checked", visible: :all

    find("label.choice", text: I18n.t("people.sex.X"), exact_text: true).click
    fill_in "person_given_names", with: "Алексей Петрович"
    assert_selector "input[name='person[sex]'][value=X]:checked", visible: :all
  end

  test "a name it can't read leaves the sex not stated" do
    fill_in "person_given_names", with: "Ada"
    fill_in "person_surname", with: "Lovelace"
    assert_selector "input[name='person[sex]'][value=U]:checked", visible: :all
  end
end
