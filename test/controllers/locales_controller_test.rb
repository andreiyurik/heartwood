require "test_helper"

class LocalesControllerTest < ActionDispatch::IntegrationTest
  test "switches the locale without authentication and sets a cookie" do
    patch locale_url, params: { locale: "ru" }
    assert_redirected_to root_url
    assert_equal "ru", cookies[:locale]
  end

  test "the chosen locale is applied to subsequently rendered pages" do
    patch locale_url, params: { locale: "ru" }
    sign_in_as users(:one)
    get people_url
    assert_select "h1", text: /Люди/
  end

  test "redirects back to the referring page when present" do
    patch locale_url, params: { locale: "en" }, headers: { "HTTP_REFERER" => new_session_url }
    assert_redirected_to new_session_url
  end

  test "an unsupported locale falls back to the default" do
    patch locale_url, params: { locale: "de" }
    assert_equal I18n.default_locale.to_s, cookies[:locale]
  end
end
