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

  test "the hero puts its promise under the marker and shows a family, not the interface" do
    get root_url
    assert_select ".landing-hero h1 mark", I18n.t("landing.hero.title_mark")
    assert_select ".landing-album img[alt=?]", I18n.t("landing.album.person")
    assert_select ".landing-album .landing-album__note", 2
  end

  test "the pain reads as before and after" do
    get root_url
    assert_select ".landing-contrast__before li", 3
    assert_select ".landing-contrast__after li", 3
  end

  test "the maker signs a letter, with initials until there is a photo" do
    get root_url
    assert_select "#letter h2", I18n.t("landing.letter.title")
    assert_select "#letter .landing-signature", text: /#{I18n.t("landing.letter.name")}/
    assert_select "#letter .avatar", text: "AY"
  end

  test "the screenshots have dark twins for dark mode" do
    get root_url
    assert_select ".landing-window picture", 2
    assert_select ".landing-window picture source[media='(prefers-color-scheme: dark)']", 2
  end

  test "the questions stack in two independent columns, each marked as expandable" do
    get root_url
    assert_select ".landing-faq > .landing-faq__column", 2
    assert_select ".landing-faq__column details", 6
    assert_select ".landing-faq summary .icon", 6
  end

  test "the map is advertised only when the install has one" do
    get root_url
    assert_select ".landing-features h3", text: I18n.t("landing.features.map_title")

    with_maps(tiles_url: "off") { get root_url }
    assert_select ".landing-features h3", text: I18n.t("landing.features.map_title"), count: 0
  end

  test "the footer names the operator once it is configured" do
    get root_url
    assert_select ".landing-footer .landing-operator", count: 0

    operator = Rails.configuration.x.operator
    original = operator.slice(:name, :inn, :ogrn, :email)
    operator.merge!(name: "ИП Иванов И. И.", inn: "770000000000", ogrn: "300000000000000", email: "hi@example.ru")
    get root_url
    assert_select ".landing-footer .landing-operator", text: /ИП Иванов И\. И\..*770000000000.*300000000000000.*hi@example\.ru/m
  ensure
    operator&.merge!(original)
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

  test "the hosted engine can add its own legal documents to the footer" do
    get root_url
    assert_select "footer #cloud-offer", count: 0

    with_cloud_slots { get root_url }
    assert_select "footer nav #cloud-offer"
  end

  test "the hosted engine can add its analytics notice to the landing page only" do
    with_cloud_slots do
      get root_url
      assert_select "#cloud-analytics"

      get privacy_url
      assert_select "#cloud-analytics", count: 0
    end
  end

  test "the family price says soon until the hosted engine names one" do
    get root_url
    assert_select "#pricing .landing-price", text: I18n.t("landing.pricing.family_price")

    with_cloud_slots { get root_url }
    assert_select "#pricing .landing-price .cloud-price", text: "1 490 ₽"
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
