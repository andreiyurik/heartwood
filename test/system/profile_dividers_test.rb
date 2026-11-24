require "application_system_test_case"

class ProfileDividersTest < ApplicationSystemTestCase
  test "an editor sees one hairline under the section links, not two" do
    person = Person.create!(given_names: "Ada", surname: "Lovelace", sex: "F", tree: trees(:alpha))
    sign_in_as users(:one)
    visit person_path(person)

    assert_selector "turbo-frame#new_question", visible: :all
    assert_equal "0px", page.evaluate_script("getComputedStyle(document.querySelector('#events')).borderTopWidth")
  end
end
