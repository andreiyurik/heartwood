require "test_helper"

class SettingsControllerTest < ActionDispatch::IntegrationTest
  setup { @tree = trees(:alpha) }

  test "the owner sees the tree name in a form" do
    sign_in_as users(:one)
    get settings_url
    assert_response :success
    assert_select "form[action=?] input[name='tree[name]'][value=?]", settings_path, @tree.name
  end

  test "the owner renames the tree" do
    sign_in_as users(:one)
    patch settings_url, params: { tree: { name: "Pushkin family" } }
    assert_redirected_to settings_url
    assert_equal "Pushkin family", @tree.reload.name
  end

  test "a blank name is rejected" do
    sign_in_as users(:one)
    patch settings_url, params: { tree: { name: "" } }
    assert_response :unprocessable_entity
    assert_equal "Alpha Tree", @tree.reload.name
  end

  test "editors cannot open or change settings" do
    editor = User.create!(name: "Ed", email_address: "ed@example.com", password: "password")
    TreeMembership.create!(user: editor, tree: @tree, role: "editor")
    sign_in_as editor

    get settings_url
    assert_redirected_to root_url
    patch settings_url, params: { tree: { name: "Hijacked" } }
    assert_equal "Alpha Tree", @tree.reload.name
  end

  test "only the owner gets the settings icon in the header" do
    sign_in_as users(:one)
    get people_url
    assert_select "#header a[href=?] .for-screen-reader", settings_path, text: I18n.t("nav.settings")

    editor = User.create!(name: "Ed", email_address: "ed@example.com", password: "password")
    TreeMembership.create!(user: editor, tree: @tree, role: "editor")
    sign_out
    sign_in_as editor
    get people_url
    assert_select "#header a[href=?]", settings_path, count: 0
  end
end
