require "test_helper"

# Every translation key defined in the source locale (en) must exist in ru. Russian
# legitimately carries extra plural/datetime forms (few/many, distance_in_words), so the
# check is asymmetric (en ⊆ ru), NOT equality — a symmetric check would false-fail on
# those forms. This guards the common regression: add an en string, forget the ru one.
class LocaleParityTest < ActiveSupport::TestCase
  LOCALE_FILES = Dir[Rails.root.join("config/locales/*.yml"), Rails.root.join("vendor/cloud/config/locales/*.yml")]

  def flatten_keys(hash, prefix = "")
    hash.each_with_object([]) do |(key, value), keys|
      full = prefix.empty? ? key.to_s : "#{prefix}.#{key}"
      value.is_a?(Hash) ? keys.concat(flatten_keys(value, full)) : keys << full
    end
  end

  test "every en locale key is present in ru" do
    en = flatten_keys(YAML.load_file(Rails.root.join("config/locales/en.yml")).fetch("en"))
    ru = flatten_keys(YAML.load_file(Rails.root.join("config/locales/ru.yml")).fetch("ru"))

    missing = en - ru
    assert_empty missing, "Keys present in en but missing in ru: #{missing.sort.join(", ")}"
  end

  # Rails ships these in English only; number.nth is English ordinals, procs no locale overrides.
  test "Rails' own English strings have Russian translations" do
    I18n.backend.send(:init_translations) unless I18n.backend.initialized?
    loaded = I18n.backend.send(:translations)
    rails_keys = flatten_keys(loaded.fetch(:en).slice(:errors, :activerecord, :date, :time, :datetime, :number, :helpers, :support))
    missing = rails_keys.grep_v(/\Anumber\.nth\./) - flatten_keys(loaded.fetch(:ru))

    assert_empty missing, "Rails' en keys missing in ru: #{missing.sort.join(", ")}"
  end

  # YAML keeps the last of two equal keys, silently dropping everything under the first.
  test "no locale file repeats a key" do
    LOCALE_FILES.each do |file|
      duplicates = []
      walk = ->(node, path) do
        next unless node.is_a?(Psych::Nodes::Mapping)
        pairs = node.children.each_slice(2).to_a
        pairs.map { |key, _| key.value }.tally.each { |key, n| duplicates << (path + [ key ]).join(".") if n > 1 }
        pairs.each { |key, value| walk.(value, path + [ key.value ]) }
      end
      walk.(Psych.parse_file(file).root, [])

      assert_empty duplicates, "#{File.basename(file)} repeats #{duplicates.join(", ")}"
    end
  end
end
