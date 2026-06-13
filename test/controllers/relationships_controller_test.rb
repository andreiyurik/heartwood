require "test_helper"

# "How are we related?" — the type-ahead frame and the named result.
class RelationshipsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @tree = trees(:alpha)
    Current.tree = @tree
    @person = Person.create!(given_names: "Pat", surname: "Root", sex: "M", tree: @tree)
    @mother = @person.add_parent(given_names: "Mary", surname: "Root", sex: "F")
    sign_in_as users(:one)
  end

  teardown { Current.reset }

  test "requires authentication" do
    sign_out
    get person_relationship_url(@person)
    assert_redirected_to new_session_url
  end

  test "show without a target renders the search frame" do
    get person_relationship_url(@person)
    assert_response :success
    assert_select "turbo-frame#relationship input[type=search]"
  end

  test "show names the relationship to the chosen person" do
    get person_relationship_url(@person, with: @mother.id)
    assert_response :success
    assert_match(/is your mother/, @response.body)
  end

  test "show reports when two people are not related" do
    stranger = Person.create!(given_names: "Stranger", sex: "U", tree: @tree)
    get person_relationship_url(@person, with: stranger.id)
    assert_response :success
    assert_match(/not related/, @response.body)
  end

  test "cannot target a person from another tree" do
    other = Person.create!(given_names: "Outsider", sex: "U", tree: trees(:beta))
    get person_relationship_url(@person, with: other.id)
    assert_response :success
    assert_select ".relationship-result", count: 0
  end

  test "search lists matching people as options" do
    get search_person_relationship_url(@person, q: "Mary")
    assert_response :success
    assert_select "a", text: /Mary Root/
  end

  test "search excludes the focus person" do
    get search_person_relationship_url(@person, q: "Pat")
    assert_response :success
    assert_no_match(/Pat Root/, @response.body)
  end

  test "search is scoped to the current tree" do
    Person.create!(given_names: "Foreigner", sex: "U", tree: trees(:beta))
    get search_person_relationship_url(@person, q: "Foreigner")
    assert_response :success
    assert_no_match(/Foreigner/, @response.body)
  end
end
