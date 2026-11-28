require "test_helper"

# docs/features/guides.md
class GuidesControllerTest < ActionDispatch::IntegrationTest
  test "the guides are public, in both languages, each under its own address" do
    Guide.all.each do |guide|
      %w[ru en].each do |locale|
        get guide_path(guide, locale: locale)
        assert_response :success
        assert_select "html[lang=?]", locale
        assert_select "h1", I18n.t("guides.#{guide.slug.underscore}.title", locale: locale)
      end
    end
  end

  test "the address's language wins over the visitor's chosen one" do
    cookies[:locale] = "en"
    get guide_path("military", locale: "ru")
    assert_select "html[lang=ru]"
  end

  test "the bare address sends the visitor to their language" do
    get "/guides", headers: { "Accept-Language" => "ru-RU,ru;q=0.9" }
    assert_redirected_to guides_path(locale: "ru")
  end

  test "an unknown guide is not found" do
    get "/ru/guides/nonsense"
    assert_response :not_found
  end

  test "the index lists every guide" do
    get guides_path(locale: "ru")
    Guide.all.each { assert_select "a[href=?]", guide_path(it, locale: "ru") }
  end

  test "a guide lists its sites as rows that open the site, and credits the methodology it is based on" do
    get guide_path("military", locale: "ru")
    ResearchSite.in_guide("military").each do |site|
      assert_select ".site-row a[href=?]", site.url, text: site.name
    end
    assert_select ".site-row", ResearchSite.in_guide("military").size
    assert_select "a[href=?]", Guide::SKILL_URL
  end

  test "a guide invites the reader to keep what they found in a tree" do
    get guide_path("military", locale: "ru")
    assert_select ".guide-cta a[href=?]", new_registration_path
  end

  test "a guide tells search engines what it is, in each language" do
    get guide_path("metric-books", locale: "ru")
    guide = Guide.find("metric-books")

    assert_select "title", /#{Regexp.escape(I18n.t("guides.metric_books.title", locale: :ru))}/
    assert_select "meta[name=description][content=?]", I18n.t("guides.metric_books.description", locale: :ru)
    assert_select "link[rel=canonical][href=?]", guide_url(guide, locale: "ru")
    assert_select "link[rel=alternate][hreflang=en][href=?]", guide_url(guide, locale: "en")
    assert_select "link[rel=alternate][hreflang=x-default][href=?]", guide_url(guide, locale: "ru")
    assert_select "meta[property='og:title']"
    assert_select "script[type='application/ld+json']", /"@type":"Article"/
  end

  test "guides stay out of search engines unless the install is the indexed one" do
    get guide_path("military", locale: "ru")
    assert_select "meta[name=robots][content=noindex]"

    with_guides_indexed do
      get guide_path("military", locale: "ru")
      assert_select "meta[name=robots]", count: 0
    end
  end

  test "the language switcher on a guide leads to the same guide in the other language" do
    get guide_path("military", locale: "ru")
    assert_select ".locale-switcher input[name=return_to][value=?]", guide_path("military", locale: "en")
  end

  test "a signed-in member reads the guides too" do
    sign_in_as users(:one)
    get guide_path("military", locale: "ru")
    assert_response :success
  end

  test "the sitemap lists the landing page and every guide in both languages, only on the indexed install" do
    get "/sitemap.xml"
    assert_response :success
    assert_no_match "<loc>", response.body

    with_guides_indexed { get "/sitemap.xml" }
    assert_equal "application/xml", response.media_type
    assert_includes response.body, "<loc>#{landing_url}</loc>"
    Guide.all.each do |guide|
      assert_includes response.body, "<loc>#{guide_url(guide, locale: "ru")}</loc>"
      assert_includes response.body, "<loc>#{guide_url(guide, locale: "en")}</loc>"
    end
  end

  test "the first guide is the method as a route, whole when nothing is answered" do
    assert_equal "start", Guide.all.first.slug

    get guide_path("start", locale: "ru")
    assert_select "form.route-form[method=get][action=?][data-turbo-frame=route]", guide_path("start", locale: "ru") do
      assert_select "input[type=radio][name=era]", ResearchRoute::ERAS.size + 1
      assert_select "input[type=radio][name=fate]", ResearchRoute::FATES.size
      assert_select "select[name=region] option", ResearchRoute::REGIONS.size + 1
    end
    assert_select "turbo-frame#route ol.route > li.route-step", ResearchRoute.new.steps.size
    assert_select ".route-step h2", text: I18n.t("research_route.steps.ask.title", locale: :ru)
    assert_select ".route-step svg.route-art", ResearchRoute.new.steps.size
    assert_select ".route-step input[type=checkbox][data-checklist-target=item]", ResearchRoute.new.steps.size
  end

  test "the answers make the route the reader's own, under an address that can be sent on" do
    get guide_path("start", locale: "ru", era: "soviet", fate: "war")
    assert_select "input[name=era][value=soviet][checked]"
    assert_select "input[name=fate][value=war][checked]"
    assert_select ".route-step", ResearchRoute.new(era: "soviet", fate: "war").steps.size
    assert_select ".route-step a[href=?]", guide_path("military", locale: "ru")
    assert_select ".route-step .site-row a[href=?]", ResearchSite.find("pamyat_naroda").url
    assert_select "link[rel=canonical][href=?]", guide_url("start", locale: "ru")
    assert_select "[data-controller~=copy-to-clipboard][data-copy-to-clipboard-content-value=?]",
      guide_url("start", locale: "ru", era: "soviet", fate: "war")
  end

  test "the route's first step leads to asking the family by link" do
    get guide_path("start", locale: "ru")
    assert_select ".route-step:first-child a[href=?]", new_registration_path
  end

  test "the landing page leads to the route" do
    get root_url
    assert_select ".landing a[href=?]", guide_path("start", locale: I18n.locale), minimum: 1
  end

  private
    def with_guides_indexed
      Rails.configuration.x.guides.indexed = true
      yield
    ensure
      Rails.configuration.x.guides.indexed = false
    end
end
