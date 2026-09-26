require "test_helper"

class CitationsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @tree   = trees(:bach)
    @person = people(:johann_sebastian)
    @event  = events(:sebastian_death)
    sign_in_as users(:bach)
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

  test "POST create stores source author, repository, and source_type" do
    post person_event_citations_url(@person, @event),
         params: { source: { title: "1881 Census", author: "GRO", repository: "TNA", source_type: "census" } }
    source = Source.find_by!(title: "1881 Census")
    assert_equal "GRO", source.author
    assert_equal "TNA", source.repository
    assert_equal "census", source.source_type
  end

  test "POST create stores citation page, quoted text, date, and confidence" do
    post person_event_citations_url(@person, @event),
         params: {
           source: { title: "Parish register" },
           citation: { page: "p. 42", text: "born the third of March", date: "1881-04-03", confidence: "very_high" }
         }
    citation = @event.reload.citations.last
    assert_equal "p. 42", citation.page
    assert_equal "born the third of March", citation.text
    assert_equal Date.new(1881, 4, 3), citation.date
    assert citation.very_high?
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

  test "a viewer cannot add or remove citations" do
    viewer = User.create!(name: "Viewer", email_address: "viewer@example.com", password: "password")
    TreeMembership.create!(user: viewer, tree: @tree, role: "viewer")
    sign_out
    sign_in_as viewer
    Current.tree = @tree

    assert_no_difference "Citation.count" do
      post person_event_citations_url(@person, @event), params: { source: { title: "Parish register" } }
    end
    assert_response :forbidden

    source   = Source.create!(title: "Vital record", tree: @tree)
    citation = Citation.create!(source: source, citable: @event)
    assert_no_difference "Citation.count" do
      delete person_event_citation_url(@person, @event, citation)
    end
    assert_response :forbidden
  end

  test "the citation form asks for source, page and confidence first" do
    get new_person_event_citation_url(@person, @event)
    assert_select "form > .field input[name='source[title]']"
    assert_select "form > .field input[name='citation[page]']"
    assert_select "form > .field select[name='citation[confidence]']"
    assert_select "form details.more-fields" do
      assert_select "input[name='source[url]']"
      assert_select "input[name='source[author]']"
      assert_select "input[name='source[repository]']"
      assert_select "textarea[name='citation[text]']"
    end
    assert_select "form > .field input[name='source[url]']", count: 0
  end
end
