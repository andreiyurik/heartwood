require "test_helper"

class MapsControllerTest < ActionDispatch::IntegrationTest
  setup { sign_in_as users(:bach) }

  test "requires authentication" do
    sign_out
    get map_url
    assert_redirected_to new_session_url
  end

  test "tree map page mounts the map controller" do
    get map_url
    assert_response :success
    assert_select "[data-controller=map]"
  end

  test "person map json lists only geolocated events" do
    people(:wilhelm_friedemann).events.create!(kind: "BIRT", date_raw: "1710", place: places(:leipzig))
    people(:wilhelm_friedemann).events.create!(kind: "DEAT", date_raw: "1784")

    get person_map_url(people(:wilhelm_friedemann), format: :json)
    assert_response :success

    data = JSON.parse(@response.body)
    assert_equal 1, data.size
    assert_equal "Leipzig, Saxony", data.first["place"]
    assert_in_delta 51.3397, data.first["lat"], 0.001
    assert_equal "Wilhelm Friedemann Bach", data.first.dig("person", "name")
  end

  test "places without coordinates are left off the map" do
    bare = Place.create!(name: "Nowhere", tree: trees(:bach))
    people(:wilhelm_friedemann).events.create!(kind: "RESI", place: bare)

    get person_map_url(people(:wilhelm_friedemann), format: :json)
    assert_response :success
    assert_equal [], JSON.parse(@response.body)
  end

  test "tree map data is scoped to the current tree" do
    foreign_place  = Place.create!(name: "Foreign", latitude: 1, longitude: 1, tree: trees(:beta))
    foreign_person = Person.create!(given_names: "Outsider", sex: "U", tree: trees(:beta))
    foreign_person.events.create!(kind: "BIRT", place: foreign_place)

    get map_events_url(format: :json)
    assert_response :success

    data = JSON.parse(@response.body)
    assert_equal [ "Eisenach, Thuringia", "Leipzig, Saxony" ], data.map { |m| m["place"] }.sort
  end
end
