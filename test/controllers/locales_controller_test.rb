require "test_helper"

# LocalesController — language switch. Works without authentication; sets a 1-year
# cookie and redirects back. The route constrains :locale to /en|ru/, so unknown
# locales are rejected at routing (404) and never reach the controller fallback.
class LocalesControllerTest < ActionDispatch::IntegrationTest
  test "switches the locale without authentication and sets a cookie" do
    get set_locale_url(locale: "ru")
    assert_redirected_to root_url
    assert_equal "ru", cookies[:locale]
  end

  test "the chosen locale is applied to subsequently rendered pages" do
    get set_locale_url(locale: "ru")
    sign_in_as users(:one)
    get people_url
    assert_select "h1", text: /Люди/
  end

  test "redirects back to the referring page when present" do
    get set_locale_url(locale: "en"), headers: { "HTTP_REFERER" => new_session_url }
    assert_redirected_to new_session_url
  end

  test "an unsupported locale is rejected by the route constraint (404)" do
    get "/locale/de"
    assert_response :not_found
  end
end
