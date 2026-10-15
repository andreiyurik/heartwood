require "test_helper"

class ApplicationHelperTest < ActionView::TestCase
  include Turbo::FramesHelper

  test "a preserved frame holds itself through a refresh from the moment it starts loading" do
    actions = Nokogiri::HTML.fragment(preserved_frame_tag("add_event") { "x" }).at("turbo-frame")["data-action"].split
    assert_includes actions, "turbo:before-fetch-request->preserve-form#hold"
    assert_includes actions, "turbo:frame-load->preserve-form#sync"
    assert_includes actions, "turbo:submit-end->preserve-form#release"
  end

  test "avatar_hue is a stable hue derived from the name" do
    assert_equal avatar_hue("Ada Lovelace"), avatar_hue("Ada Lovelace")
    assert_includes 0...360, avatar_hue("Ada Lovelace")
    assert_not_equal avatar_hue("Ada Lovelace"), avatar_hue("Charles Babbage")
  end
end
