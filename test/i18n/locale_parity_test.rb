require "test_helper"

# Every translation key defined in the source locale (en) must exist in ru. Russian
# legitimately carries extra plural/datetime forms (few/many, distance_in_words), so the
# check is asymmetric (en ⊆ ru), NOT equality — a symmetric check would false-fail on
# those forms. This guards the common regression: add an en string, forget the ru one.
class LocaleParityTest < ActiveSupport::TestCase
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
end
