require "test_helper"

class LandingControllerTest < ActionDispatch::IntegrationTest
  test "a guest at the root sees the landing page" do
    get root_url
    assert_response :success
    assert_select "h1", hero_title
    assert_select "title", I18n.t("landing.meta.title")
    assert_select "a[href=?]", new_registration_path, minimum: 2
    assert_select "a[href=?]", new_session_path
  end

  test "the hero puts its promise under the marker" do
    get root_url
    assert_select ".landing-hero h1 mark", I18n.t("landing.hero.title_mark")

    get root_url, headers: { "Accept-Language" => "ru" }
    assert_select ".landing-hero h1 mark", I18n.t("landing.hero.title_mark", locale: :ru)
  end

  test "the hero tells the product's story as one scene that plays once" do
    get root_url, headers: { "Accept-Language" => "ru" }
    assert_select ".landing-hero .landing-scene.landing-scene--playing[data-controller=scene]" do
      assert_select "svg.landing-scene__tree[role=img][aria-label]" do
        assert_select ".landing-scene__person", 6
        assert_select ".landing-scene__person--found .landing-scene__name", "Прасковья"
        assert_select ".landing-scene__slot", 1
      end
      assert_select "button[data-action='scene#replay'][aria-label=?]", I18n.t("landing.scene.replay", locale: :ru)
    end
  end

  test "the question and the answer look like the family chat they travel through" do
    get root_url, headers: { "Accept-Language" => "ru" }
    assert_select ".landing-scene .chat-bubble--out", /Как звали маму бабушки Анны/ do
      assert_select ".chat-bubble__link", I18n.t("landing.scene.ask_link", locale: :ru)
      assert_select "time", "12:04"
    end
    assert_select ".landing-scene .chat-bubble--typing[aria-hidden=true] i", 3
    assert_select ".landing-scene .chat-bubble--in", /Прасковья Ильинична/ do
      assert_select ".chat-bubble__name", "Тётя Вера"
      assert_select ".chat-bubble__via", I18n.t("landing.scene.answer_via", locale: :ru)
      assert_select "img.chat-bubble__photo[data-scene-target=from][src*='scene-found']"
    end
  end

  test "the ancestors have faces and the living have initials; the found one's photograph flies in from the chat" do
    get root_url
    assert_select ".landing-scene__tree image", 2
    assert_select ".landing-scene__person--grandmother image[href*='scene-grandmother']"
    assert_select ".landing-scene__person--you image", count: 0
    assert_select ".landing-scene__canvas img.landing-scene__flight[data-scene-target=to][src*='scene-found'][alt='']"
  end

  test "the hero starts a tree from the family's name, and the scene's tree takes that name and crest" do
    get root_url
    assert_select ".landing-hero[data-controller~=crest-preview]" do
      assert_select "form.landing-start[action=?][method=get]", new_registration_path do
        assert_select "input[name=tree_name][maxlength='240'][data-action='input->crest-preview#draw']"
        assert_select "[data-crest-preview-target=crest] svg.crest"
        assert_select "button[type=submit]", I18n.t("landing.hero.cta")
      end
      assert_select ".landing-scene__title [data-crest-preview-target=crest] svg.crest"
      assert_select ".landing-scene__title [data-crest-preview-target=title]", I18n.t("landing.scene.family")
    end
  end

  test "a guest can flip the theme from the header" do
    get root_url
    assert_select "#header button.btn[data-controller=theme][data-action='theme#toggle'][aria-label=?]", I18n.t("theme.toggle")
  end

  test "the example tree is one click away when the install has one" do
    get root_url
    assert_select "a", text: I18n.t("landing.hero.demo"), count: 0

    with_demo_url("/shared/abc") { get root_url }
    assert_select ".landing-hero a[href='/shared/abc']", text: I18n.t("landing.hero.demo")
  end

  test "the example is found by its owner's account, with no link to copy" do
    owner = User.create!(email_address: "demo@example.invalid", name: "Demo", password: SecureRandom.base58(32))
    tree = Tree.create!(name: "Example").tap { it.tree_memberships.create!(user: owner, role: "owner") }

    with_demo_owner(owner.email_address) { get root_url }
    assert_select "a", text: I18n.t("landing.hero.demo"), count: 0

    link = tree.create_share_link!
    with_demo_owner(owner.email_address) { get root_url }
    assert_select ".landing-hero a[href=?]", shared_tree_path(link.token), text: I18n.t("landing.hero.demo")

    with_demo_owner(owner.email_address) { with_demo_url("/shared/abc") { get root_url } }
    assert_select ".landing-hero a[href='/shared/abc']"
  end

  test "the footer leads to the guides in the visitor's language" do
    get root_url, headers: { "Accept-Language" => "ru" }
    assert_select ".landing-footer a[href=?]", guides_path(locale: "ru"), text: I18n.t("guides.index.title", locale: :ru)
  end

  test "the pain reads as before and after" do
    get root_url
    assert_select ".landing-contrast__before li", 3
    assert_select ".landing-contrast__after li", 3
  end

  test "the maker's signed letter belongs to the hosted engine, not to every install" do
    get root_url
    assert_select "#letter", count: 0

    with_cloud_slots { get root_url }
    assert_select "#letter h2", I18n.t("landing.letter.title")
    assert_select "#letter .landing-signature .avatar"
    assert_select "#letter .landing-signature", text: /#{I18n.t("landing.letter.name")}/
  end

  test "asking for support belongs to the hosted engine; an install of its own asks for nothing" do
    get root_url
    assert_select "#support", count: 0
    assert_no_match "cloudtips", response.body

    with_cloud_slots { get root_url }
    assert_select "#letter ~ #support"
  end

  test "the screenshots have dark twins that follow the theme" do
    get root_url
    assert_select ".landing-window img.only-light[loading=lazy]", 2
    assert_select ".landing-window img.only-dark[loading=lazy][src*='.dark']", 2
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
    assert_select "h1", hero_title
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
    assert_select "h1", hero_title(locale: :ru)

    get root_url, headers: { "Accept-Language" => "de-DE,de;q=0.9" }
    assert_select "html[lang=en]"

    cookies[:locale] = "en"
    get root_url, headers: { "Accept-Language" => "ru-RU" }
    assert_select "html[lang=en]"
  end

  private
    def hero_title(locale: I18n.locale)
      I18n.t("landing.hero.title_html", mark: I18n.t("landing.hero.title_mark", locale:), locale:)
    end

    def with_demo_owner(email)
      Rails.configuration.x.landing.demo_owner = email
      yield
    ensure
      Rails.configuration.x.landing.demo_owner = nil
    end

    def with_demo_url(url)
      Rails.configuration.x.landing.demo_url = url
      yield
    ensure
      Rails.configuration.x.landing.demo_url = nil
    end
end
