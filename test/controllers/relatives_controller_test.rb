require "test_helper"

# Adding relatives to a Person through the UI. See docs/features/person-profile.md.
class RelativesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @tree   = trees(:alpha)
    @person = Person.create!(given_names: "Pat", surname: "Root", sex: "U", tree: @tree)
    sign_in_as users(:one)
    Current.tree = @tree
  end

  test "requires authentication" do
    sign_out
    get new_person_relative_url(@person, relation: "parent")
    assert_redirected_to new_session_url
  end

  test "adds a parent" do
    assert_difference "Person.count", 1 do
      post person_relatives_url(@person), params: {
        relation: "parent", person: { given_names: "Mary", surname: "Root", sex: "F" }
      }
    end
    assert_redirected_to person_url(@person)
    assert_includes @person.parents.map(&:given_names), "Mary"
  end

  test "adds a child" do
    post person_relatives_url(@person), params: {
      relation: "child", person: { given_names: "Kim", sex: "U" }
    }
    assert_includes @person.children.map(&:given_names), "Kim"
  end

  test "adds a partner" do
    post person_relatives_url(@person), params: {
      relation: "partner", person: { given_names: "Sam", sex: "M" }
    }
    assert_includes @person.partners.map(&:given_names), "Sam"
  end

  test "new renders an inline form for the relation" do
    get new_person_relative_url(@person, relation: "child")
    assert_response :success
    assert_select "form"
    assert_select "input[name=relation][value=child]"
  end

  test "create via turbo_stream replaces the family box" do
    post person_relatives_url(@person),
      params: { relation: "child", person: { given_names: "Kim", sex: "U" } },
      as: :turbo_stream
    assert_response :success
    assert_select "turbo-stream[action=replace][target=family]"
  end

  test "rejects an unknown relation without creating anyone" do
    assert_no_difference "Person.count" do
      post person_relatives_url(@person), params: {
        relation: "alien", person: { given_names: "Zorp" }
      }
    end
    assert_response :unprocessable_entity
  end

  # --- Linking an existing person (combobox path) ---

  test "links an existing person as a parent instead of creating one" do
    existing = Person.create!(given_names: "Existing", surname: "Root", sex: "F", tree: @tree)
    assert_no_difference "Person.count" do
      post person_relatives_url(@person), params: {
        relation: "parent", existing_person_id: existing.id
      }
    end
    assert_includes @person.parents, existing
  end

  test "cannot link a person from another tree" do
    other = Person.create!(given_names: "Outsider", sex: "U", tree: trees(:beta))
    assert_no_difference "Person.count" do
      post person_relatives_url(@person), params: {
        relation: "parent", existing_person_id: other.id
      }
    end
    assert_response :not_found
    assert_not_includes @person.parents, other
  end

  # --- Combobox search for existing people ---

  test "search lists matching tree people as linkable options" do
    Person.create!(given_names: "Findme", surname: "X", sex: "U", tree: @tree)
    get search_person_relatives_url(@person, relation: "parent", q: "Findme")
    assert_response :success
    assert_select "button", text: /Findme X/
  end

  test "search excludes the focus person and already-linked relatives" do
    linked = Person.create!(given_names: "Findme", surname: "Linked", sex: "F", tree: @tree)
    @person.add_parent(linked)
    get search_person_relatives_url(@person, relation: "parent", q: "Findme")
    assert_response :success
    assert_no_match(/Findme Linked/, @response.body)
  end

  test "search is scoped to the current tree" do
    Person.create!(given_names: "Foreigner", sex: "U", tree: trees(:beta))
    get search_person_relatives_url(@person, relation: "parent", q: "Foreigner")
    assert_response :success
    assert_no_match(/Foreigner/, @response.body)
  end

  test "search with a blank query lists nothing" do
    Person.create!(given_names: "Somebody", sex: "U", tree: @tree)
    get search_person_relatives_url(@person, relation: "parent", q: "")
    assert_response :success
    assert_select "#relative_candidates button", count: 0
  end
end
