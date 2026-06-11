require "test_helper"

class PeopleControllerTest < ActionDispatch::IntegrationTest
  setup do
    @tree   = trees(:alpha)
    @person = Person.create!(given_names: "Ada", surname: "Lovelace", sex: "F", tree: @tree)
    sign_in_as users(:one)
    Current.tree = @tree
  end

  test "requires authentication" do
    sign_out
    get people_url
    assert_redirected_to new_session_url
  end

  test "lists people when signed in" do
    get people_url
    assert_response :success
    assert_select "body", /Lovelace/
  end

  test "shows a person" do
    get person_url(@person)
    assert_response :success
    assert_select "body", /Ada Lovelace/
  end

  test "creates a person" do
    assert_difference "Person.count", 1 do
      post people_url, params: { person: { given_names: "Grace", surname: "Hopper", sex: "F" } }
    end
    assert_redirected_to person_url(Person.last)
    assert_equal "Hopper", Person.last.surname
  end

  test "updates a person" do
    patch person_url(@person), params: { person: { nickname: "The Countess" } }
    assert_redirected_to person_url(@person)
    assert_equal "The Countess", @person.reload.nickname
  end

  test "destroys a person" do
    assert_difference "Person.count", -1 do
      delete person_url(@person)
    end
    assert_redirected_to people_url
  end
end
