require "test_helper"

class SharedControllerTest < ActionDispatch::IntegrationTest
  setup do
    @tree   = trees(:bach)
    @link   = @tree.create_share_link!
    @dead   = people(:johann_sebastian)
    @living = @tree.people.create!(given_names: "Lina", surname: "Bach")
  end

  test "a guest sees the whole tree without signing in, and living people stay nameless" do
    get shared_tree_url(@link.token)

    assert_response :success
    assert_select ".tree-node a[href=?]", shared_person_path(@link.token, @dead)
    assert_no_match "Lina", response.body
    assert_select "a[href=?]", new_registration_path
  end

  test "a guest reads a deceased person's page, with no way to edit" do
    get shared_person_url(@link.token, @dead)

    assert_response :success
    assert_select "h1", text: /#{@dead.given_names}/
    assert_select "form:not([action=?])", locale_path, count: 0
    assert_select "a[href^='/people']", count: 0
  end

  test "a living person's page is not there" do
    get shared_person_url(@link.token, @living)
    assert_response :not_found
  end

  test "people from another tree are not reachable through the link" do
    stranger = trees(:alpha).people.create!(given_names: "Stranger")
    stranger.events.create!(kind: "DEAT", date_raw: "1800")

    get shared_person_url(@link.token, stranger)
    assert_response :not_found
  end

  test "an unknown or turned-off link is not found" do
    token = @link.token
    @link.destroy!

    get shared_tree_url(token)
    assert_response :not_found
  end

  test "pages ask search engines to stay away and don't leak the URL as a referrer" do
    get shared_tree_url(@link.token)

    assert_equal "noindex, nofollow", response.headers["X-Robots-Tag"]
    assert_equal "no-referrer", response.headers["Referrer-Policy"]
  end

  test "a signed-in member of another tree still sees only what a guest sees" do
    sign_in_as users(:one)

    get shared_person_url(@link.token, @living)
    assert_response :not_found
  end
end
