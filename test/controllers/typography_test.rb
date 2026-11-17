require "test_helper"

class TypographyTest < ActionDispatch::IntegrationTest
  FONTS = Rails.root.join("app/assets/fonts")
  STYLES = Rails.root.join("app/assets/stylesheets")

  test "the interface is set in Golos Text, with the system font as the fallback" do
    assert_match(/--font-family: "Golos Text", ui-sans-serif, system-ui/, STYLES.join("base.css").read)
    assert_match(/--font-hand: "Caveat"/, STYLES.join("base.css").read)
  end

  test "every font face points at a file that ships with the app" do
    faces = STYLES.join("fonts.css").read.scan(/url\("([^"]+)"\)/).flatten
    assert_equal 8, faces.size
    faces.each { assert FONTS.join(it).exist?, "#{it} is missing" }
    assert_match(/font-display: swap/, STYLES.join("fonts.css").read)
  end

  test "no page asks a font server abroad for anything" do
    sources = Dir[Rails.root.join("app/{views,assets/stylesheets,javascript}/**/*")].select { File.file?(it) }
    sources.each { assert_no_match(/fonts\.(googleapis|gstatic)\.com/, File.read(it), it) }
  end

  test "the fonts come with their licences" do
    %w[OFL-golos-text.txt OFL-caveat.txt].each { assert_match "SIL Open Font License", FONTS.join(it).read }
    assert_match "Golos Text", Rails.root.join("NOTICE.md").read
  end

  test "the page preloads the face its language needs" do
    get new_session_url, headers: { "Accept-Language" => "ru" }
    assert_select "link[rel=preload][as=font][type='font/woff2'][crossorigin][href*='golos-text-cyrillic']"

    get new_session_url, headers: { "Accept-Language" => "en" }
    assert_select "link[rel=preload][as=font][href*='golos-text-latin']"
    assert_select "link[rel=preload][as=font][href*='golos-text-cyrillic']", count: 0
  end

  test "a photo's caption is written by hand" do
    assert_match(/\.photo__caption \{[^}]*font-family: var\(--font-hand\)/m, STYLES.join("photos.css").read)
  end

  test "empty places carry a small drawing instead of bare words" do
    get join_url("NOPE-0000-CODE")
    assert_select ".auth-card svg.drawing"

    sign_in_as users(:one)
    get people_url
    assert_select ".blank-slate svg.drawing"
  end
end
