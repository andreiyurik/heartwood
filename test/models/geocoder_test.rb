require "test_helper"

class GeocoderTest < ActiveSupport::TestCase
  test "a blank query returns no candidates without any lookup" do
    assert_equal [], Geocoder.search("")
    assert_equal [], Geocoder.search(nil)
  end

  test "maps Nominatim results into candidate hashes" do
    geocoder = Geocoder.new
    def geocoder.request(_query, _limit)
      [ { "display_name" => "Boston, Suffolk County, Massachusetts, USA",
          "lat" => "42.3601", "lon" => "-71.0589" } ]
    end

    candidate = geocoder.search("Boston").first
    assert_equal "Boston", candidate[:name]
    assert_equal "Boston, Suffolk County, Massachusetts, USA", candidate[:display_name]
    assert_in_delta 42.3601, candidate[:lat], 0.0001
    assert_in_delta(-71.0589, candidate[:lng], 0.0001)
  end

  test "a lookup error degrades to an empty list" do
    geocoder = Geocoder.new
    def geocoder.request(_query, _limit) = raise("boom")
    assert_equal [], geocoder.search("Boston")
  end
end
