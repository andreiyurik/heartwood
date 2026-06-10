require "test_helper"

# Adding relatives to a Person through the UI. See docs/features/person-profile.md.
class RelativesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @person = Person.create!(given_names: "Pat", surname: "Root", sex: "U")
    sign_in_as users(:one)
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
end
