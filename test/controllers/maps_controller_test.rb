require "test_helper"

class MapsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @tree = trees(:alpha)
    Current.tree = @tree
    @person = Person.create!(given_names: "Pat", surname: "Root", sex: "M", tree: @tree)
    @place  = Place.create!(name: "Boston", latitude: 42.36, longitude: -71.05, tree: @tree)
    sign_in_as users(:one)
  end

  teardown { Current.reset }

  test "requires authentication" do
    sign_out
    get tree_map_url
    assert_redirected_to new_session_url
  end

  test "tree map page mounts the map controller" do
    get tree_map_url
    assert_response :success
    assert_select "[data-controller=map]"
  end

  test "person map json lists only geolocated events" do
    @person.events.create!(kind: "BIRT", date_raw: "1900", place: @place)
    @person.events.create!(kind: "DEAT", date_raw: "1980") # no place → off the map

    get map_person_url(@person, format: :json)
    assert_response :success

    data = JSON.parse(@response.body)
    assert_equal 1, data.size
    assert_equal "Boston", data.first["place"]
    assert_in_delta 42.36, data.first["lat"], 0.001
    assert_equal "Pat Root", data.first.dig("person", "name")
  end

  test "places without coordinates are left off the map" do
    bare = Place.create!(name: "Nowhere", tree: @tree)
    @person.events.create!(kind: "RESI", place: bare)

    get map_person_url(@person, format: :json)
    assert_response :success
    assert_equal [], JSON.parse(@response.body)
  end

  test "tree map data is scoped to the current tree" do
    @person.events.create!(kind: "RESI", place: @place)
    foreign_place  = Place.create!(name: "Foreign", latitude: 1, longitude: 1, tree: trees(:beta))
    foreign_person = Person.create!(given_names: "Outsider", sex: "U", tree: trees(:beta))
    foreign_person.events.create!(kind: "BIRT", place: foreign_place)

    get tree_map_events_url(format: :json)
    assert_response :success

    data = JSON.parse(@response.body)
    assert_equal [ "Boston" ], data.map { |m| m["place"] }
  end
end
