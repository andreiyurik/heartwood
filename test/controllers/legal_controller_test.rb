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
