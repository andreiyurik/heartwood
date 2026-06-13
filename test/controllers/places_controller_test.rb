require "test_helper"

class PlacesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @tree = trees(:alpha)
    Current.tree = @tree
    sign_in_as users(:one)
  end

  teardown { Current.reset }

  test "requires authentication" do
    sign_out
    get search_places_url(q: "Bos")
    assert_redirected_to new_session_url
  end

  test "search lists matching places in the tree as options" do
    Place.create!(name: "Boston", tree: @tree)
    get search_places_url(q: "Bos")
    assert_response :success
    assert_select "button[data-place-name=?]", "Boston"
  end

  test "search is scoped to the current tree" do
    Place.create!(name: "Foreignville", tree: trees(:beta))
    get search_places_url(q: "Foreign")
    assert_response :success
    assert_no_match(/Foreignville/, @response.body)
  end

  test "search returns a bare fragment, never the page layout" do
    get search_places_url(q: "Nowhere")
    assert_response :success
    assert_no_match(/<html/, @response.body)
    assert_select "header", false
  end

  test "geocode responds with a json array (empty for a blank query, no network)" do
    get geocode_places_url(q: "")
    assert_response :success
    assert_equal [], JSON.parse(@response.body)
  end

  test "geocode requires authentication" do
    sign_out
    get geocode_places_url(q: "Boston")
    assert_redirected_to new_session_url
  end
end
