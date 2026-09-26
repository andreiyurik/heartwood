require "test_helper"

class LayoutTest < ActionDispatch::IntegrationTest
  setup { sign_in_as users(:one) }

  test "declares the page language" do
    get people_url
    assert_select "html[lang=en]"

    get set_locale_url(locale: "ru")
    get people_url
    assert_select "html[lang=ru]"
  end

  test "offers a skip link to the main content" do
    get people_url
    assert_select "a.skip-navigation[href='#main-content']", text: I18n.t("nav.skip_to_content")
    assert_select "main#main-content"
  end

  test "labels the language switcher in the current locale" do
    get set_locale_url(locale: "ru")
    get people_url
    assert_select "nav.locale-switcher[aria-label=?]", I18n.t("locale.switcher", locale: :ru)
  end

  test "loads the leaflet stylesheet once" do
    get people_url
    assert_select "link[rel=stylesheet][href*=leaflet]", count: 1
  end
end
