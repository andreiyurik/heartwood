require "test_helper"

class CloudHelperTest < ActionView::TestCase
  test "a slot renders nothing when no cloud engine provides it" do
    assert_nil view.cloud_slot("family_price")
  end

  test "a slot renders the cloud engine's partial with its locals" do
    view.lookup_context.prepend_view_paths [ file_fixture("cloud_views").to_s ]

    assert_dom_equal '<strong class="cloud-price">1 490 ₽</strong>', view.cloud_slot("family_price").strip
    assert_match trees(:alpha).name, view.cloud_slot("family_price", tree: trees(:alpha))
  end
end
