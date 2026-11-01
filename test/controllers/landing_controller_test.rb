require "test_helper"

class LandingControllerTest < ActionDispatch::IntegrationTest
  test "a guest at the root sees the landing page" do
    get root_url
    assert_response :success
    assert_select "h1", I18n.t("landing.hero.title")
    assert_select "title", I18n.t("landing.meta.title")
    assert_select "a[href=?]", new_registration_path, minimum: 2
    assert_select "a[href=?]", new_session_path
  end

  test "a signed-in person at the root goes straight to their tree" do
    sign_in_as users(:one)
    get root_url
    assert_response :success
    assert_select "h1", I18n.t("people.title")
  end

  test "a stale session cookie counts as a guest" do
    sign_in_as users(:one)
    Session.delete_all
    get root_url
    assert_select "h1", I18n.t("landing.hero.title")
  end

  test "links the legal documents and the source code" do
    get root_url
    assert_select "footer a[href=?]", privacy_path
    assert_select "footer a[href=?]", terms_path
    assert_select "footer a[href=?]", Heartwood::SOURCE_CODE_URL
  end

  test "the free plan's limit comes from the plans" do
    get root_url
    assert_match Tree::PLANS["free"][:people_limit].to_s, css_select("#pricing").text
  end

  test "describes itself for search engines and link previews" do
    get root_url
    assert_select "meta[name=description][content=?]", I18n.t("landing.meta.description")
    assert_select "meta[property='og:title']"
  end

  test "says the data stays in Russia only when the operator says where it is hosted" do
    get root_url
    assert_no_match I18n.t("landing.trust.russia_title"), response.body

    original = Rails.configuration.x.operator
    Rails.configuration.x.operator = original.merge(hosting: "Yandex Cloud, Москва")
    get root_url
    assert_match I18n.t("landing.trust.russia_title"), response.body
  ensure
    Rails.configuration.x.operator = original
  end

  test "speaks the visitor's language until they choose one" do
    get root_url, headers: { "Accept-Language" => "ru-RU,ru;q=0.9,en;q=0.8" }
    assert_select "html[lang=ru]"
    assert_select "h1", I18n.t("landing.hero.title", locale: :ru)

    get root_url, headers: { "Accept-Language" => "de-DE,de;q=0.9" }
    assert_select "html[lang=en]"

    cookies[:locale] = "en"
    get root_url, headers: { "Accept-Language" => "ru-RU" }
    assert_select "html[lang=en]"
  end
end
