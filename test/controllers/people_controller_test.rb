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

  test "profile defaults to details tab" do
    get person_url(@person)
    assert_select ".profile-tab--active", text: /Details/i
    assert_select ".facts"
  end

  test "profile renders sources tab" do
    get person_url(@person, tab: "sources")
    assert_response :success
    assert_select ".profile-tab--active", text: /Sources/i
  end

  test "profile renders memories tab" do
    get person_url(@person, tab: "memories")
    assert_response :success
    assert_select ".profile-tab--active", text: /Memories/i
  end

  test "profile renders timeline tab" do
    get person_url(@person, tab: "timeline")
    assert_response :success
    assert_select ".profile-tab--active", text: /Timeline/i
  end

  test "unknown tab falls back to details" do
    get person_url(@person, tab: "hacker/../../etc")
    assert_response :success
    assert_select ".profile-tab--active", text: /Details/i
  end

  test "index search filters by name" do
    hidden = Person.create!(given_names: "Turing", surname: "Alan", sex: "M", tree: @tree)
    get people_url(q: "Lovelace")
    assert_select "body", /Lovelace/
    assert_select "body", text: /Turing/, count: 0
  end

  test "index sex filter narrows results" do
    get people_url(sex: "F")
    assert_select "body", /Lovelace/
  end

  test "index renders search form" do
    get people_url
    assert_select "form[data-controller='search']"
    assert_select "input[type='search']"
  end

  test "creates a person" do
    assert_difference "Person.count", 1 do
      post people_url, params: { person: { given_names: "Grace", surname: "Hopper", sex: "F" } }
    end
    assert_redirected_to person_url(Person.last)
    assert_equal "Hopper", Person.last.surname
  end

  test "create with invalid params re-renders the form (422)" do
    assert_no_difference "Person.count" do
      post people_url, params: { person: { given_names: "Bad", sex: "Z" } }
    end
    assert_response :unprocessable_entity
  end

  test "updates a person" do
    patch person_url(@person), params: { person: { nickname: "The Countess" } }
    assert_redirected_to person_url(@person)
    assert_equal "The Countess", @person.reload.nickname
  end

  test "update with invalid params re-renders the form (422) and leaves the record unchanged" do
    patch person_url(@person), params: { person: { sex: "Z" } }
    assert_response :unprocessable_entity
    assert_equal "F", @person.reload.sex
  end

  test "updates a person's biography" do
    patch person_url(@person), params: { person: { biography: "Born by the sea." } }
    assert_redirected_to person_url(@person)
    assert_equal "Born by the sea.", @person.reload.biography.to_plain_text
  end

  test "show renders the biography on the profile" do
    @person.update!(biography: "A life of quiet adventure.")
    get person_url(@person)
    assert_response :success
    assert_select ".biography", text: /A life of quiet adventure/
  end

  test "edit renders the Lexxy rich-text editor for the biography" do
    get edit_person_url(@person)
    assert_response :success
    assert_select "lexxy-editor"
  end

  test "destroys a person" do
    assert_difference "Person.count", -1 do
      delete person_url(@person)
    end
    assert_redirected_to people_url
  end
end
