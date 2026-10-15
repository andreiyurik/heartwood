require "test_helper"

class LayoutTest < ActionDispatch::IntegrationTest
  setup do
    Person.create!(given_names: "Ada", surname: "Lovelace", sex: "F", tree: trees(:alpha))
    sign_in_as users(:one)
  end

  test "declares the page language" do
    get people_url
    assert_select "html[lang=en]"

    patch locale_url, params: { locale: "ru" }
    get people_url
    assert_select "html[lang=ru]"
  end

  test "offers a skip link to the main content" do
    get people_url
    assert_select "a.skip-navigation[href='#main']", text: I18n.t("nav.skip_to_content")
    assert_select "main#main"
  end

  test "the language switcher submits a PATCH to the locale resource" do
    get people_url
    assert_select "nav.locale-switcher form[action=?][method=post] input[name=_method][value=patch]", locale_path, minimum: 2
  end

  test "labels the language switcher in the current locale" do
    patch locale_url, params: { locale: "ru" }
    get people_url
    assert_select "nav.locale-switcher[aria-label=?]", I18n.t("locale.switcher", locale: :ru)
  end

  test "loads the leaflet stylesheet once" do
    get people_url
    assert_select "link[rel=stylesheet][href*=leaflet]", count: 1
  end

  test "frames every page with a header and a main area" do
    get people_url
    assert_select "body > header#header"
    assert_select "body > main#main"
  end

  test "the header shows the tree name as a breadcrumb and the page title is the sheet's heading" do
    get people_url
    assert_select "#header nav.breadcrumbs a[href=?]", root_path, text: /Alpha Tree/
    assert_select "#header h1", count: 0
    assert_select "main#main > header.page-header h1", text: I18n.t("people.title")
  end

  test "a person page opens with the name as the title and the life years as the metadata line" do
    person = Person.create!(given_names: "Ada", surname: "Lovelace", sex: "F", tree: trees(:alpha))
    Event.create!(kind: "BIRT", eventable: person, tree: trees(:alpha), date_raw: "1815", date_start: Date.new(1815, 12, 10))
    get person_url(person)
    assert_select "main#main > header.page-header" do
      assert_select "h1", text: "Ada Lovelace"
      assert_select ".page-header__meta", text: /1815/
    end
  end

  test "full-bleed pages keep the title in the toolbar instead of a sheet heading" do
    get clan_tree_url
    assert_select "header.page-header", count: 0
    assert_select "#header .breadcrumbs .breadcrumbs__page", text: I18n.t("nav.tree")
  end

  test "the same People / Tree / Map navigation is on every page, marking the current one" do
    get clan_tree_url
    assert_select "nav.sections[aria-label=?]", I18n.t("nav.sections") do
      assert_select "a", count: 3
      assert_select "a[aria-current=page]", text: I18n.t("nav.tree")
      assert_select "a[href=?]", root_path, text: I18n.t("nav.people")
      assert_select "a[href=?]", map_path, text: I18n.t("nav.map")
    end
  end

  test "the account menu gathers members, language and sign out behind the avatar" do
    get people_url
    assert_select "#header details.account-menu" do
      assert_select "summary .avatar", text: "UO"
      assert_select "menu.action-sheet a[href=?]", tree_memberships_path, text: I18n.t("nav.members")
      assert_select "menu.action-sheet nav.locale-switcher"
      assert_select "menu.action-sheet form[action=?] button", session_path, text: I18n.t("nav.sign_out")
    end
  end

  test "settings appear in the account menu only for the owner" do
    get people_url
    assert_select "details.account-menu a[href=?]", settings_path
    viewer = User.create!(name: "Viewer Vee", email_address: "vee@example.com", password: "password")
    TreeMembership.create!(user: viewer, tree: trees(:alpha), role: "viewer")
    sign_in_as viewer
    get people_url
    assert_select "details.account-menu a[href=?]", settings_path, count: 0
  end

  test "pages hand their actions to the header" do
    get people_url
    assert_select "#header .header-actions a[href=?]", new_person_path
  end

  test "tree and map are full-bleed through a class on the body" do
    place = Place.create!(name: "London", latitude: 51.5, longitude: -0.12, tree: trees(:alpha))
    Event.create!(kind: "BIRT", eventable: Person.last, tree: trees(:alpha), place: place)
    get clan_tree_url
    assert_select "body.full-bleed"
    get map_url
    assert_select "body.full-bleed"
    get people_url
    assert_select "body.full-bleed", count: 0
  end

  test "person pages offer a back button" do
    person = Person.create!(given_names: "Ada", surname: "Lovelace", sex: "F", tree: trees(:alpha))
    get person_url(person)
    assert_select "#header a.back[href=?] .for-screen-reader", people_path, text: I18n.t("nav.back")
  end

  test "page titles read page, tree, then Heartwood" do
    person = Person.create!(given_names: "Ada", surname: "Lovelace", sex: "F", tree: trees(:alpha))
    get person_url(person)
    assert_select "title", "Ada Lovelace · Alpha Tree · Heartwood"
  end

  test "flash messages pop up as a toast that removes itself" do
    patch active_tree_url(tree_id: trees(:beta).id)
    follow_redirect!
    assert_select ".flash.flash--alert[data-controller=element-removal][data-action*='animationend->element-removal#remove']",
      text: /#{I18n.t("active_tree.flash.not_a_member")}/
  end

  test "an unknown page renders the branded 404" do
    Rails.application.env_config["action_dispatch.show_detailed_exceptions"] = false
    get join_url("nope")
    assert_response :not_found
    assert_select "title", /Heartwood/
    assert_select "a[href='/']"
  ensure
    Rails.application.env_config.delete("action_dispatch.show_detailed_exceptions")
  end
end
