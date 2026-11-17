require "test_helper"

class ClanTreesControllerTest < ActionDispatch::IntegrationTest
  test "GET show renders the родовое древо rooted at the progenitor" do
    sign_in_as users(:bach)
    get clan_tree_url
    assert_response :success
    assert_select "[data-tree-mode-value='descendants']"
    assert_select ".tree-node--focus[data-tree-node-id='#{people(:ambrosius).id}']"
  end

  test "GET show embeds graph JSON with unions" do
    sign_in_as users(:bach)
    get clan_tree_url
    assert_select "[data-tree-graph-value*='unions']"
  end

  test "GET show shows an empty state for a tree with no people" do
    sign_in_as users(:one)
    get clan_tree_url
    assert_response :success
    assert_select ".tree-canvas", count: 0
    assert_select ".blank-slate"
  end

  test "GET show requires authentication" do
    sign_out
    get clan_tree_url
    assert_redirected_to new_session_url
  end

  test "the clan tree is a sheet page with a title, a summary line and no instruction strip" do
    sign_in_as users(:bach)
    get clan_tree_url
    assert_select "body.full-bleed", count: 0
    assert_select "main#main > header.page-header h1", text: I18n.t("nav.tree")
    assert_select ".page-header__meta", text: "7 people · 3 generations · from Johann Ambrosius Bach"
    assert_select ".tree-hint", count: 0
    assert_select "#header .breadcrumbs__page", count: 0
  end

  test "search sits in the action row above the canvas and the controls are our round buttons" do
    sign_in_as users(:bach)
    get clan_tree_url
    assert_select ".tree-page[data-controller=tree] .tree-actions .search-field input.tree-search-input"
    assert_select ".tree-canvas .tree-search", count: 0
    assert_select ".tree-zoom button.btn.btn--round", count: 3
    assert_select ".tree-zoom button[title=?]", I18n.t("trees.zoom_fit")
    assert_select ".tree-zoom .tree-print-btn", count: 0
    assert_select "#header details.action-menu button[data-controller=print][data-print-tree-outlet='.tree-page']",
      text: I18n.t("trees.print")
    assert_select ".tree-canvas .tree-tip[data-tree-target=tip]", text: I18n.t("trees.tip")
  end

  test "a tree of one person offers the next step instead of an empty canvas" do
    me = Person.create!(given_names: "Maria", surname: "Ivanova", sex: "F", tree: trees(:alpha))
    sign_in_as users(:one)
    get clan_tree_url

    assert_select ".tree-node--focus[data-tree-node-id='#{me.id}']"
    assert_select ".tree-node--ghost a[href*=?]", new_person_relative_path(me, relation: "parent")
    assert_select ".page-header__meta", text: "1 person · 1 generation"
  end

  test "the tree does not pay per person for dates and portraits" do
    sign_in_as users(:bach)
    count = 0
    counter = ->(*, payload) { count += 1 if payload[:sql].match?(/FROM "(events|active_storage_attachments)"/) && !payload[:cached] }
    ActiveSupport::Notifications.subscribed(counter, "sql.active_record") { get clan_tree_url }

    assert_operator count, :<=, 7
  end
end
