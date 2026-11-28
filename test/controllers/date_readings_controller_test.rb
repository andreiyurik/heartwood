require "test_helper"

# docs/domain/event.md "Typing a date"
class DateReadingsControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in_as users(:one)
    patch locale_url, params: { locale: "ru" }
  end

  test "a typed date comes back the way the app read it, day first" do
    get date_reading_url(date: "12.03.1901", frame: "person_born_reading")
    assert_response :success
    assert_select "turbo-frame#person_born_reading .date-reading__date", "12 марта 1901"
  end

  test "a year, a month or an approximate date is read as it is, with no day invented" do
    { "1901" => "1901", "март 1901" => "март 1901", "около 1890" => "ок. 1890", "до 1917" => "до 1917" }.each do |typed, read|
      get date_reading_url(date: typed, frame: "f")
      assert_select ".date-reading__date", read
      assert_select "turbo-frame button", count: 0
    end
  end

  test "a full date before the 1918 calendar change can be marked Old Style in one click" do
    get date_reading_url(date: "12.03.1901", frame: "f")
    assert_select "button[type=button][data-action='date-reading#oldStyle'][data-date-reading-suffix-param=?]",
      I18n.t("date_readings.old_style_suffix", locale: :ru), text: I18n.t("date_readings.old_style", locale: :ru)

    get date_reading_url(date: "14.02.1918", frame: "f")
    assert_select "turbo-frame button", count: 0
  end

  test "an Old Style date shows its modern equivalent" do
    get date_reading_url(date: "12 марта 1885 ст. ст.", frame: "f")
    assert_select ".date-reading__date", "12 марта 1885 (ст. ст.)"
    assert_select ".date-reading", /24 марта 1885/
    assert_select "turbo-frame button", count: 0
  end

  test "the suffix the button adds is one the parser reads, in every language" do
    I18n.available_locales.each do |locale|
      assert FuzzyDate.parse("12.03.1901 #{I18n.t("date_readings.old_style_suffix", locale:)}").julian?, locale
    end
  end

  test "a text the app can't read is kept as written, and it says so" do
    get date_reading_url(date: "весна 1812", frame: "f")
    assert_select ".date-reading__date", count: 0
    assert_select ".date-reading", /#{I18n.t("date_readings.as_written", locale: :ru)}/
  end

  test "nothing typed, nothing said; and only a frame name is ever echoed" do
    get date_reading_url(date: " ", frame: "f")
    assert_select "turbo-frame#f", ""

    get date_reading_url(date: "1901", frame: "x\"><script>")
    assert_response :bad_request
  end

  test "it is for people working on a tree" do
    delete session_url
    get date_reading_url(date: "1901", frame: "f")
    assert_redirected_to new_session_url
  end
end
