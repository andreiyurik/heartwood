require "test_helper"

# Adding/editing a Person's life events through the UI. See docs/domain/event.md,
# docs/features/person-profile.md.
class EventsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @tree   = trees(:bach)
    @person = people(:wilhelm_friedemann)
    sign_in_as users(:bach)
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

  test "a viewer sees no event or citation controls on the person page" do
    viewer = User.create!(name: "Viewer", email_address: "viewer@example.com", password: "password")
    TreeMembership.create!(user: viewer, tree: @tree, role: "viewer")
    event = @person.events.create!(kind: "BIRT", date_raw: "1815")
    sign_out
    sign_in_as viewer

    get person_url(@person)
    assert_select "a[href=?]", edit_person_event_path(@person, event), count: 0
    assert_select "form[action=?]", person_event_path(@person, event), count: 0
    assert_select "a[href=?]", new_person_event_citation_path(@person, event), count: 0
  end

  test "a viewer cannot add, edit, or remove events" do
    viewer = User.create!(name: "Viewer", email_address: "viewer@example.com", password: "password")
    TreeMembership.create!(user: viewer, tree: @tree, role: "viewer")
    sign_out
    sign_in_as viewer
    Current.tree = @tree

    assert_no_difference "@person.events.count" do
      post person_events_url(@person), params: { event: { kind: "BIRT", date_raw: "1815" } }
    end
    assert_response :forbidden

    event = @person.events.create!(kind: "BIRT", date_raw: "1815")
    patch person_event_url(@person, event), params: { event: { date_raw: "1900" } }
    assert_response :forbidden
    assert_equal "1815", event.reload.date_raw

    assert_no_difference "Event.count" do
      delete person_event_url(@person, event)
    end
  end
end
