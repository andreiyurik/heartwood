require "test_helper"

# Adding/editing a Person's life events through the UI. See docs/domain/event.md,
# docs/features/person-profile.md.
class EventsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @tree   = trees(:alpha)
    @person = Person.create!(given_names: "Ada", surname: "Lovelace", sex: "F", tree: @tree)
    sign_in_as users(:one)
    Current.tree = @tree
  end

  test "requires authentication" do
    sign_out
    get new_person_event_url(@person)
    assert_redirected_to new_session_url
  end

  test "adds an event" do
    assert_difference "@person.events.count", 1 do
      post person_events_url(@person), params: { event: { kind: "BIRT", date_raw: "10 DEC 1815" } }
    end
    assert_redirected_to person_url(@person)
    assert_equal "10 DEC 1815", @person.birth.date_raw
  end

  test "rejects an event without a kind" do
    assert_no_difference "Event.count" do
      post person_events_url(@person), params: { event: { kind: "", date_raw: "1815" } }
    end
    assert_response :unprocessable_entity
  end

  test "updates an event" do
    event = @person.events.create!(kind: "BIRT", date_raw: "1815")
    patch person_event_url(@person, event), params: { event: { date_raw: "10 DEC 1815" } }
    assert_redirected_to person_url(@person)
    assert_equal "10 DEC 1815", event.reload.date_raw
  end

  test "removes an event" do
    event = @person.events.create!(kind: "DEAT")
    assert_difference "Event.count", -1 do
      delete person_event_url(@person, event)
    end
    assert_redirected_to person_url(@person)
  end

  test "new renders an inline event form" do
    get new_person_event_url(@person)
    assert_response :success
    assert_select "form"
    assert_select "select[name=?]", "event[kind]"
  end

  test "create via turbo_stream replaces the events box" do
    post person_events_url(@person),
      params: { event: { kind: "BIRT", date_raw: "1815" } }, as: :turbo_stream
    assert_response :success
    assert_select "turbo-stream[action=replace][target=events]"
  end
end
