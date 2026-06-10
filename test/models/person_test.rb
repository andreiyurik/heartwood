require "test_helper"

# Person (INDI) — see docs/domain/person.md
class PersonTest < ActiveSupport::TestCase
  test "is valid with a given name and surname" do
    person = Person.new(given_names: "John Fitzgerald", surname: "Kennedy")
    assert person.valid?
  end

  test "display_name composes prefix, given names, surname and suffix" do
    person = Person.new(
      name_prefix: "Dr.", given_names: "John Fitzgerald",
      surname: "Kennedy", name_suffix: "Jr."
    )
    assert_equal "Dr. John Fitzgerald Kennedy Jr.", person.display_name
  end

  test "display_name omits blank parts" do
    assert_equal "Kennedy", Person.new(surname: "Kennedy").display_name
    assert_equal "John", Person.new(given_names: "John").display_name
  end

  test "display_name falls back to Unknown when no name is present" do
    assert_equal "Unknown", Person.new.display_name
  end

  test "sex defaults to U (unknown)" do
    assert_equal "U", Person.new.sex
  end

  test "sex must be a valid GEDCOM code" do
    %w[M F U X].each do |code|
      assert Person.new(sex: code).valid?, "#{code} should be valid"
    end
    person = Person.new(sex: "Z")
    assert_not person.valid?
    assert_includes person.errors[:sex], "is not included in the list"
  end
end
