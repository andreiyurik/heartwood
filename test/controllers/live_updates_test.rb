require "test_helper"

class LiveUpdatesControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in_as users(:bach)
    @person = people(:johann_sebastian)
  end

  def stream_sources
    css_select("turbo-cable-stream-source").size
  end

  test "pages that show the tree's data listen for changes" do
    [ people_url, person_url(@person), person_tree_url(@person), clan_tree_url, map_url ].each do |url|
      get url
      assert_operator css_select("turbo-cable-stream-source").size, :>=, 2, "#{url} should listen to the tree (plus the hints badge)"
    end
  end

  test "forms do not listen, so a refresh can't wipe what someone is typing" do
    [ new_person_url, edit_person_url(@person), new_import_url ].each do |url|
      get url
      assert_equal 1, css_select("turbo-cable-stream-source").size, "#{url} should only carry the hints badge stream"
    end
  end

  test "tree and map pages replace on refresh, since their canvas is laid out by JavaScript" do
    get person_tree_url(@person)
    assert_select "meta[name=turbo-refresh-method][content=replace]"
    get clan_tree_url
    assert_select "meta[name=turbo-refresh-method][content=replace]"
    get map_url
    assert_select "meta[name=turbo-refresh-method][content=replace]"
  end

  test "other pages morph on refresh" do
    get person_url(@person)
    assert_select "meta[name=turbo-refresh-method][content=morph]"
    assert_select "meta[name=turbo-refresh-scroll][content=preserve]"
  end
end
