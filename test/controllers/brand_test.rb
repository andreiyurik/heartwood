require "test_helper"

class BrandTest < ActionDispatch::IntegrationTest
  test "guests see the mark and the name, not an emoji" do
    get new_session_url
    assert_select "#header a.brand svg.logo"
    assert_select "#header a.brand", text: "Heartwood"
    assert_no_match "🌳", response.body
  end

  test "the name comes from the brand setting, in every locale" do
    with_brand "Вся родня" do
      get new_session_url, headers: { "Accept-Language" => "ru" }
      assert_select "#header a.brand", text: "Вся родня"
      assert_select "title", text: /Вся родня/
      assert_no_match "Heartwood", response.body

      get root_url, headers: { "Accept-Language" => "ru" }
      assert_select "title", text: /\AВся родня/
      assert_select ".landing-footer", text: /Вся родня/
    end
  end

  test "no Russian sentence declines the brand name" do
    I18n.with_locale(:ru) do
      with_brand "Вся родня" do
        strings(I18n.t(".", locale: :ru)).grep(/Вся родня/).each do |string|
          assert_no_match(/(\A|[\s«(])(в|во|с|со|из|для|от|к|у|о|об|на|свой|вашего|код|автор|команда)\s+«?Вся родня/i, string)
        end
      end
    end
  end

  test "the layout links the web app manifest and real icons" do
    get new_session_url
    assert_select "link[rel=manifest][href=?]", pwa_manifest_path(format: :json)
    assert_select "link[rel=icon][href='/icon.svg']"
    assert_select "link[rel=apple-touch-icon][href='/icon.png']"
  end

  test "the manifest names the app and its colours" do
    with_brand "Вся родня" do
      get pwa_manifest_url(format: :json)
      manifest = response.parsed_body
      assert_equal "Вся родня", manifest["name"]
      assert_equal "standalone", manifest["display"]
      assert_no_match "red", response.body
      assert_includes manifest["icons"].map { it["sizes"] }, "192x192"
    end
  end

  test "the icon is no longer the Rails placeholder" do
    assert_no_match "red", Rails.public_path.join("icon.svg").read
  end

  test "every tree wears a crest with its initial" do
    Person.create!(given_names: "Ada", surname: "Lovelace", sex: "F", tree: trees(:alpha))
    sign_in_as users(:one)
    get people_url
    assert_select "#header .tree-name svg.crest text", text: "A"
    assert_no_match "🌳", response.body
  end

  private
    def with_brand(name)
      original = Rails.configuration.x.brand.name
      Rails.configuration.x.brand.name = name
      yield
    ensure
      Rails.configuration.x.brand.name = original
    end

    def strings(node)
      case node
      when Hash then node.values.flat_map { strings(it) }
      when Array then node.flat_map { strings(it) }
      when String then [ node.gsub("%{app}", Rails.configuration.x.brand.name) ]
      else []
      end
    end
end
