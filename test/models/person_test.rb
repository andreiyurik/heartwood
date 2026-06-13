require "test_helper"

# Person (INDI) — see docs/domain/person.md
class PersonTest < ActiveSupport::TestCase
  test "is valid with a given name and surname" do
    person = Person.new(given_names: "John Fitzgerald", surname: "Kennedy", tree: trees(:alpha))
    assert person.valid?
  end

  test "has a rich text biography" do
    person = Person.create!(sex: "U", tree: trees(:alpha))
    person.update!(biography: "<div>A <strong>remarkable</strong> life.</div>")
    assert_equal "A remarkable life.", person.reload.biography.to_plain_text
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
      assert Person.new(sex: code, tree: trees(:alpha)).valid?, "#{code} should be valid"
    end
    person = Person.new(sex: "Z", tree: trees(:alpha))
    assert_not person.valid?
    assert_includes person.errors[:sex], "is not included in the list"
  end

  test "requires a tree" do
    person = Person.new(sex: "U")
    assert_not person.valid?
    assert person.errors[:tree].any?
  end

  test "destroying a person removes its events and family memberships but keeps the family" do
    tree   = trees(:alpha)
    person = Person.create!(sex: "F", tree: tree)
    Event.create!(kind: "BIRT", eventable: person, tree: tree)
    family = Family.create!(tree: tree)
    family.partners << person

    assert_difference "FamilyPartner.count", -1 do
      assert_difference "Event.count", -1 do
        person.destroy
      end
    end
    assert Family.exists?(family.id), "the family itself must not be destroyed"
  end
end
