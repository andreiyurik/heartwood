require "test_helper"

class CrestIconsTest < ActionDispatch::IntegrationTest
  setup do
    @tree = trees(:alpha)
    sign_in_as users(:one)
  end

  test "the browser tab wears the tree's crest" do
    get people_url
    assert_select "link[rel=icon][type='image/svg+xml'][href^=?]", crest_icon_path

    get crest_icon_url
    assert_equal "image/svg+xml", response.media_type
    assert_match %r{\A<svg xmlns="http://www.w3.org/2000/svg"}, response.body
    assert_match @tree.crest_shape_path, response.body
  end

  test "an uploaded crest picture is the icon itself" do
    @tree.crest_image.attach(io: file_fixture("avatar.png").open, filename: "crest.png", content_type: "image/png")

    get crest_icon_url
    assert_response :redirect
  end

  test "guests keep the service's mark" do
    sign_out
    get new_session_url
    assert_select "link[rel=icon][href='/icon.svg']"
  end
end
