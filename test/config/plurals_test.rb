require "test_helper"

class PluralsTest < ActiveSupport::TestCase
  test "russian counts pick one, few and many by their last digits" do
    I18n.with_locale(:ru) do
      assert_equal [ "Загружен 1 человек", "Загружено 2 человека", "Загружено 5 человек", "Загружено 11 человек",
        "Загружен 21 человек", "Загружено 22 человека", "Загружено 112 человек" ],
        [ 1, 2, 5, 11, 21, 22, 112 ].map { I18n.t("imports.show.completed", count: it) }
    end
  end

  test "a russian one-form carries its count, so 21 isn't read as one" do
    I18n.with_locale(:ru) do
      assert_equal "21 минута", I18n.t("datetime.distance_in_words.x_minutes", count: 21)
      assert_equal "около 21 часа", I18n.t("datetime.distance_in_words.about_x_hours", count: 21)
      assert_match "21 ошибка", I18n.t("forms.errors", count: 21)
    end
  end

  test "english keeps one and other" do
    assert_equal I18n.t("imports.show.completed.other", count: 5), I18n.t("imports.show.completed", count: 5)
  end
end
