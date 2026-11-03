require "test_helper"

class PluralsTest < ActiveSupport::TestCase
  test "russian counts pick one, few and many by their last digits" do
    I18n.with_locale(:ru) do
      assert_equal [ "Загружен 1 человек", "Загружено 2 человека", "Загружено 5 человек", "Загружено 11 человек",
        "Загружен 21 человек", "Загружено 22 человека", "Загружено 112 человек" ],
        [ 1, 2, 5, 11, 21, 22, 112 ].map { I18n.t("imports.show.completed", count: it) }
    end
  end

  test "english keeps one and other" do
    assert_equal I18n.t("imports.show.completed.other", count: 5), I18n.t("imports.show.completed", count: 5)
  end
end
