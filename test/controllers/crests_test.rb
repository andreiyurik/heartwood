require "test_helper"

class CrestsTest < ActionDispatch::IntegrationTest
  setup do
    @tree = trees(:alpha)
    Person.create!(given_names: "Ada", surname: "Lovelace", sex: "F", tree: @tree)
    sign_in_as users(:one)
  end

  test "settings offer every shape, colour and symbol, each saving itself" do
    get settings_url
    assert_select "form.crest-form[data-controller=auto-submit]" do
      assert_select "input[type=radio][name='tree[crest_shape]']", Tree::Crest::SHAPES.size
      assert_select "input[type=radio][name='tree[crest_hue]']", Tree::Crest::HUES.size
      assert_select "input[type=radio][name='tree[crest_symbol]']", Tree::Crest::SYMBOLS.size + 1
      assert_select "input[type=radio][data-action='change->auto-submit#submit']", minimum: 10
    end
    assert_select "input[type=file][name='tree[crest_image]']"
  end

  test "choosing parts changes the crest in the header" do
    patch settings_url, params: { tree: { crest_shape: "round", crest_hue: "260", crest_symbol: "anchor" } }
    assert_redirected_to settings_url

    get people_url
    assert_select "#header .tree-name svg.crest[data-shape=round][data-symbol=anchor]"
    assert_select "#header .tree-name svg.crest[style*='--avatar-hue: 260']"
    assert_select "#header .tree-name svg.crest text", count: 0
  end

  test "an uploaded crest replaces the drawn one until it is removed" do
    patch settings_url, params: { tree: { crest_image: fixture_file_upload("avatar.png", "image/png") } }
    assert @tree.reload.crest_image.attached?

    get people_url
    assert_select "#header .tree-name img.crest"
    assert_select "#header .tree-name svg.crest", count: 0

    delete settings_crest_image_url
    assert_redirected_to settings_url
    assert_not @tree.reload.crest_image.attached?
  end

  test "an editor cannot change the crest" do
    tree_memberships(:one_alpha).update!(role: "editor")
    patch settings_url, params: { tree: { crest_symbol: "star" } }
    assert_response :forbidden
    delete settings_crest_image_url
    assert_response :forbidden
  end

  test "the invitation link previews with the family's card" do
    sign_out
    get join_url(@tree.join_code)
    assert_select "meta[property='og:image'][content=?]", join_card_url(@tree.join_code, format: :png)
    assert_select "meta[property='og:title'][content=?]", I18n.t("joins.heading", tree: @tree.name)

    get join_card_url(@tree.join_code, format: :png)
    assert_response :success
    assert_equal "image/png", response.media_type
    assert response.body.b.start_with?("\x89PNG".b)
    assert_match "max-age", response.headers["Cache-Control"]

    get join_card_url("NOPE-0000-CODE", format: :png)
    assert_response :not_found
  end

  test "a view-only link previews with the card too, and stays out of indexes" do
    link = ShareLink.create!(tree: @tree)
    sign_out

    get shared_tree_url(link.token)
    assert_select "meta[property='og:image'][content=?]", shared_card_url(link.token, format: :png)

    get shared_card_url(link.token, format: :png)
    assert_response :success
    assert_equal "image/png", response.media_type
    assert_equal "noindex, nofollow", response.headers["X-Robots-Tag"]
  end

  test "the owner sees how the link will look in a chat" do
    get tree_memberships_url
    assert_select "#invite img.invite-card[src=?]", join_card_path(@tree.join_code, format: :png)
  end

  test "an empty tree invites its owner to pick a crest" do
    @tree.people.destroy_all
    get people_url
    assert_select ".blank-slate a[href=?]", settings_path(anchor: "crest")
  end
end
