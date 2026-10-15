require "test_helper"

class ApplicationHelperTest < ActionView::TestCase
  test "avatar_hue is a stable hue derived from the name" do
    assert_equal avatar_hue("Ada Lovelace"), avatar_hue("Ada Lovelace")
    assert_includes 0...360, avatar_hue("Ada Lovelace")
    assert_not_equal avatar_hue("Ada Lovelace"), avatar_hue("Charles Babbage")
  end
end
