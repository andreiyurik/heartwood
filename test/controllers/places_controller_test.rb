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
end
