require "test_helper"

class PlaceGeocodeJobTest < ActiveJob::TestCase
  setup { Current.tree = trees(:alpha) }
  teardown { Current.reset }

  test "a new place without coordinates is queued for geocoding" do
    assert_enqueued_with(job: PlaceGeocodeJob) do
      Place.create!(name: "Boston", tree: Current.tree)
    end
  end

  test "a place created with coordinates is not queued" do
    assert_no_enqueued_jobs do
      Place.create!(name: "Paris", latitude: 48.8566, longitude: 2.3522, tree: Current.tree)
    end
  end

  test "performing on an already-geocoded place makes no network call" do
    place = Place.create!(name: "Paris", latitude: 48.8566, longitude: 2.3522, tree: Current.tree)
    assert_nothing_raised { PlaceGeocodeJob.new.perform(place) }
  end
end
