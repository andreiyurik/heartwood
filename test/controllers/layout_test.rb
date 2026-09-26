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

  test "the header shows the tree name and the page as breadcrumbs" do
    get people_url
    assert_select "#header nav.breadcrumbs" do
      assert_select "a[href=?]", root_path, text: /Alpha Tree/
      assert_select "h1", text: I18n.t("people.title")
    end
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

  test "members and sign out are icon buttons with screen-reader labels" do
    get people_url
    assert_select "#header a[href=?] .for-screen-reader", tree_memberships_path, text: I18n.t("nav.members")
    assert_select "#header form[action=?] .for-screen-reader", session_path, text: I18n.t("nav.sign_out")
  end

  test "pages hand their actions to the header" do
    get people_url
    assert_select "#header .header-actions a[href=?]", new_person_path
  end

  test "tree and map are full-bleed through a class on the body" do
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
