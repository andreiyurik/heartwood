require "test_helper"

class EventRowTest < ActionDispatch::IntegrationTest
  test "on a phone an event's three controls fold into one menu" do
    person = trees(:alpha).people.create!(given_names: "Vera")
    event  = person.events.create!(kind: "BIRT", date_raw: "1921")
    sign_in_as users(:one)

    get person_url(person)
    assert_select "##{dom_id(event)} details.event-menu menu.action-sheet" do
      assert_select "a[href=?]", new_person_event_citation_path(person, event)
      assert_select "a[href=?]", edit_person_event_path(person, event)
      assert_select "form[action=?]", person_event_path(person, event)
    end
  end
end
