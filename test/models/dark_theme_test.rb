require "test_helper"

# docs/architecture/design-system.md "Theme": the dark values apply by system setting and by choice.
class DarkThemeTest < ActiveSupport::TestCase
  test "the chosen dark theme and the system one are the same values" do
    css = Rails.root.join("app/assets/stylesheets/colors.css").read
    by_system = css[/:root:not\(\[data-theme="light"\]\) \{(.*?)\n  \}/m, 1]
    by_choice = css[/^:root\[data-theme="dark"\] \{(.*?)\n\}/m, 1]

    assert by_system.present? && by_choice.present?
    assert_equal by_system.lines.map(&:strip), by_choice.lines.map(&:strip)
  end
end
