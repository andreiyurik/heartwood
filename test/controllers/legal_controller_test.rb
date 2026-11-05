require "test_helper"

class LegalControllerTest < ActionDispatch::IntegrationTest
  test "the policy, consent and terms are public" do
    [ privacy_path, consent_path, terms_path ].each do |path|
      get path
      assert_response :success
      assert_select "h1"
    end
  end

  test "the documents name the operator from configuration" do
    with_operator(name: "ООО «Корни»", inn: "7700000000", email: "privacy@example.ru") do
      get privacy_path
      assert_match "ООО «Корни»", response.body
      assert_match "7700000000", response.body
      assert_match "privacy@example.ru", response.body
    end
  end

  test "a missing operator detail is visible, not blank" do
    with_operator(name: nil) do
      get privacy_path
      assert_select ".legal__missing"
    end
  end

  test "the hosted engine can name its own processors in the policy, in both languages" do
    [ "en", "ru" ].each do |locale|
      cookies[:locale] = locale
      get privacy_path
      assert_select "#cloud-processors", count: 0

      with_cloud_slots { get privacy_path }
      assert_select "article.legal #cloud-processors"
    end
  end

  test "the terms keep a consumer's statutory rights and say who may use the service" do
    { "ru" => [ "как есть", "14 лет", "1253.1" ], "en" => [ "as is", "14", "1253.1" ] }.each do |locale, (gone, age, takedown)|
      cookies[:locale] = locale
      get terms_path
      assert_no_match gone, response.body
      assert_match age, response.body
      assert_match takedown, response.body
    end
  end

  test "the consent covers what other members enter about the person" do
    cookies[:locale] = "ru"
    get consent_path
    assert_match "внесут другие участники", response.body
  end

  test "the policy names the basis for relatives' data" do
    { "ru" => "п. 7 ч. 1 ст. 6", "en" => "art. 6(1)(7)" }.each do |locale, basis|
      cookies[:locale] = locale
      get privacy_path
      assert_match basis, response.body
    end
  end

  test "documents follow the interface language" do
    get privacy_path
    assert_select "h1", I18n.t("legal.privacy.title", locale: :en)

    cookies[:locale] = "ru"
    get privacy_path
    assert_select "h1", I18n.t("legal.privacy.title", locale: :ru)
  end

  private
    def with_operator(**details)
      original = Rails.configuration.x.operator
      Rails.configuration.x.operator = original.merge(details)
      yield
    ensure
      Rails.configuration.x.operator = original
    end
end
