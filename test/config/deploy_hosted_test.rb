require "test_helper"
require "kamal"

class DeployHostedTest < ActiveSupport::TestCase
  test "the hosted deploy really sends the map switches" do
    clear = YAML.load_file(Rails.root.join("config/deploy.hosted.yml")).dig("env", "clear")
    args = Kamal::Utils.argumentize("--env", clear)

    # Kamal drops an empty value to a bare "--env KEY", which falls back to the OSM defaults.
    assert_includes args, 'MAP_TILES_URL="off"'
    assert_includes args, 'GEOCODER_URL="off"'
  end
end
