require "test_helper"

# Place — normalized event locations. The raw string is kept; coordinates are
# best-effort. Also covers Event#place_name, the find-or-create the form leans on.
class PlaceTest < ActiveSupport::TestCase
  setup { Current.tree = trees(:alpha) }
  teardown { Current.reset }

  test "requires a name" do
    assert_not Place.new(tree: Current.tree).valid?
  end

  test "search matches a name fragment within the tree" do
    Place.create!(name: "Boston", tree: Current.tree)
    Place.create!(name: "Boise",  tree: Current.tree)
    Place.create!(name: "Boston", tree: trees(:beta))
    assert_equal [ "Boston" ], Current.tree.places.search("bost").pluck(:name)
  end

  test "search with a blank query returns nothing" do
    Place.create!(name: "Boston", tree: Current.tree)
    assert_empty Place.search("")
  end

  test "geocoded? reflects whether coordinates are present" do
    assert_not Place.new(name: "X").geocoded?
    assert     Place.new(name: "X", latitude: 1, longitude: 2).geocoded?
  end

  test "Event#place_name find-or-creates a single tree place" do
    person = Person.create!(given_names: "P", sex: "U", tree: Current.tree)
    birth  = person.events.create!(kind: "BIRT", place_name: "Boston")
    resi   = person.events.create!(kind: "RESI", place_name: "Boston")

    assert_equal "Boston", birth.place.name
    assert_equal birth.place, resi.place
    assert_equal 1, Current.tree.places.where(name: "Boston").count
  end

  test "blank place_name clears the place" do
    person = Person.create!(given_names: "P", sex: "U", tree: Current.tree)
    event  = person.events.create!(kind: "BIRT", place_name: "Boston")
    event.update!(place_name: "")
    assert_nil event.reload.place
  end

  test "coordinates picked on the map create a geocoded place" do
    person = Person.create!(given_names: "P", sex: "U", tree: Current.tree)
    event  = person.events.create!(kind: "BIRT", place_name: "Boston",
                                   place_latitude: "42.3601", place_longitude: "-71.0589")
    assert event.place.geocoded?
    assert_in_delta 42.3601, event.place.latitude.to_f, 0.0001
  end
end
