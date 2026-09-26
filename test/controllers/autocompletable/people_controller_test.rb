require "test_helper"

class Autocompletable::PeopleControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in_as users(:bach)
    @person = people(:johann_sebastian)
  end

  test "an unknown purpose is rejected" do
    get autocompletable_people_url(person_id: @person.id, for: "../../etc", q: "bach")
    assert_response :unprocessable_entity
  end

  test "a missing purpose is rejected" do
    get autocompletable_people_url(person_id: @person.id, q: "bach")
    assert_response :unprocessable_entity
  end

  test "another tree's person is not found" do
    foreign = Person.create!(given_names: "Out", surname: "Sider", tree: trees(:beta))
    get autocompletable_people_url(person_id: foreign.id, for: "relative", q: "bach")
    assert_response :not_found
  end

  test "relative results post the link back to the person's relatives" do
    get autocompletable_people_url(person_id: @person.id, for: "relative", relation: "parent", q: "Barbara")
    assert_select "turbo-frame#relative_candidates form[action=?]", person_relatives_path(@person)
  end

  test "relationship results link to the relationship page" do
    get autocompletable_people_url(person_id: @person.id, for: "relationship", q: "Ambrosius")
    assert_select "turbo-frame#relationship_candidates a[href=?]", person_relationship_path(@person, with: people(:ambrosius).id)
  end
end
