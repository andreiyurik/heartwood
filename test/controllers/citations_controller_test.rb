require "test_helper"

class CitationsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @tree   = trees(:alpha)
    @person = Person.create!(given_names: "Ada", sex: "F", tree: @tree)
    @event  = Event.create!(kind: "BIRT", eventable: @person, tree: @tree)
    sign_in_as users(:one)
    Current.tree = @tree
  end

  test "GET new renders citation form in turbo frame" do
    get new_person_event_citation_url(@person, @event)
    assert_response :success
    assert_select "form"
  end

  test "POST create adds a source citation to the event" do
    assert_difference "Citation.count", 1 do
      assert_difference "Source.count", 1 do
        post person_event_citations_url(@person, @event),
             params: { source: { title: "Parish register", url: "", citation_text: "" } }
      end
    end
    assert_equal 1, @event.reload.citations.count
  end

  test "POST create reuses an existing source with the same title" do
    existing = Source.create!(title: "Parish register", tree: @tree)
    assert_no_difference "Source.count" do
      assert_difference "Citation.count", 1 do
        post person_event_citations_url(@person, @event),
             params: { source: { title: "Parish register", url: "", citation_text: "" } }
      end
    end
  end

  test "create with a blank source title re-renders the form (422)" do
    assert_no_difference [ "Source.count", "Citation.count" ] do
      post person_event_citations_url(@person, @event), params: { source: { title: "" } }
    end
    assert_response :unprocessable_entity
  end

  test "DELETE destroy removes the citation" do
    source   = Source.create!(title: "Vital record", tree: @tree)
    citation = Citation.create!(source: source, citable: @event)

    assert_difference "Citation.count", -1 do
      delete person_event_citation_url(@person, @event, citation)
    end
  end

  test "cross-tenant citation create returns 404" do
    other_person = Person.create!(sex: "M", tree: trees(:beta))
    other_event  = Event.create!(kind: "BIRT", eventable: other_person, tree: trees(:beta))

    post person_event_citations_url(other_person, other_event),
         params: { source: { title: "Stolen record" } }
    assert_response :not_found
  end
end
