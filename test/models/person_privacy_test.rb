require "test_helper"

# Living-person privacy: who can see whom, and when are graph nodes redacted.
# Member = any user with a TreeMembership in the person's tree.
# Outsider = authenticated user who is NOT a member of that tree.
# Guest = nil (unauthenticated).
class PersonPrivacyTest < ActiveSupport::TestCase
  setup do
    @tree     = trees(:alpha)
    @member   = users(:one)   # owns tree :alpha
    @outsider = users(:two)   # owns tree :beta, not :alpha
  end

  # -----------------------------------------------------------------------
  # living?
  # -----------------------------------------------------------------------

  test "living? is true when person has no events" do
    person = Person.create!(sex: "U", tree: @tree)
    assert person.living?
  end

  test "living? is false when person has a death event" do
    person = Person.create!(sex: "U", tree: @tree)
    Event.create!(kind: "DEAT", eventable: person, tree: @tree)
    assert_not person.living?
  end

  test "living? is false when buried (no explicit death event)" do
    person = Person.create!(sex: "U", tree: @tree)
    Event.create!(kind: "BURI", eventable: person, tree: @tree)
    assert_not person.living?
  end

  test "living? is false when born more than #{Person::LIVING_CUTOFF_YEARS} years ago" do
    person = Person.create!(sex: "U", tree: @tree)
    old_date = (Person::LIVING_CUTOFF_YEARS + 1).years.ago.to_date
    Event.create!(kind: "BIRT", eventable: person, tree: @tree, date_start: old_date)
    assert_not person.living?
  end

  test "living? is true when born fewer than #{Person::LIVING_CUTOFF_YEARS} years ago" do
    person = Person.create!(sex: "U", tree: @tree)
    Event.create!(kind: "BIRT", eventable: person, tree: @tree, date_start: 30.years.ago.to_date)
    assert person.living?
  end

  test "living? is true when birth event has no parsed date (raw string only)" do
    person = Person.create!(sex: "U", tree: @tree)
    Event.create!(kind: "BIRT", eventable: person, tree: @tree, date_raw: "ABT 1890")
    assert person.living?
  end

  # -----------------------------------------------------------------------
  # visible_to? — instance method
  # -----------------------------------------------------------------------

  test "living person is visible to tree member" do
    person = Person.create!(sex: "U", tree: @tree)
    assert person.living?
    assert person.visible_to?(@member)
  end

  test "living person is not visible to outsider" do
    person = Person.create!(sex: "U", tree: @tree)
    assert_not person.visible_to?(@outsider)
  end

  test "living person is not visible to guest (nil)" do
    person = Person.create!(sex: "U", tree: @tree)
    assert_not person.visible_to?(nil)
  end

  test "deceased person is visible to outsider" do
    person = Person.create!(sex: "U", tree: @tree)
    Event.create!(kind: "DEAT", eventable: person, tree: @tree)
    assert person.visible_to?(@outsider)
  end

  test "old enough person is visible to outsider" do
    person = Person.create!(sex: "U", tree: @tree)
    old_date = (Person::LIVING_CUTOFF_YEARS + 1).years.ago.to_date
    Event.create!(kind: "BIRT", eventable: person, tree: @tree, date_start: old_date)
    assert person.visible_to?(@outsider)
  end

  test "private deceased person is NOT visible to outsider" do
    person = Person.create!(sex: "U", tree: @tree, private: true)
    Event.create!(kind: "DEAT", eventable: person, tree: @tree)
    assert_not person.visible_to?(@outsider)
  end

  test "private person IS visible to tree member" do
    person = Person.create!(sex: "U", tree: @tree, private: true)
    assert person.visible_to?(@member)
  end

  # -----------------------------------------------------------------------
  # Person.visible_to scope — SQL-level
  # -----------------------------------------------------------------------

  test "scope returns all people to a tree member" do
    living = Person.create!(sex: "U", tree: @tree)
    dead   = Person.create!(sex: "U", tree: @tree).tap do |p|
      Event.create!(kind: "DEAT", eventable: p, tree: @tree)
    end

    visible = @tree.people.visible_to(@member)
    assert_includes visible, living
    assert_includes visible, dead
  end

  test "scope hides living people from outsider" do
    living = Person.create!(sex: "U", tree: @tree)
    dead   = Person.create!(sex: "U", tree: @tree).tap do |p|
      Event.create!(kind: "DEAT", eventable: p, tree: @tree)
    end

    visible = @tree.people.visible_to(@outsider)
    assert_not_includes visible, living
    assert_includes     visible, dead
  end

  test "scope hides old-birth people when also private from outsider" do
    private_old = Person.create!(sex: "U", tree: @tree, private: true)
    old_date = (Person::LIVING_CUTOFF_YEARS + 1).years.ago.to_date
    Event.create!(kind: "BIRT", eventable: private_old, tree: @tree, date_start: old_date)

    assert_not_includes @tree.people.visible_to(@outsider), private_old
  end

  test "scope shows old-birth person to outsider when not private" do
    old_person = Person.create!(sex: "U", tree: @tree)
    old_date = (Person::LIVING_CUTOFF_YEARS + 1).years.ago.to_date
    Event.create!(kind: "BIRT", eventable: old_person, tree: @tree, date_start: old_date)

    assert_includes @tree.people.visible_to(@outsider), old_person
  end

  test "scope hides everyone from guest (nil)" do
    living = Person.create!(sex: "U", tree: @tree)
    dead   = Person.create!(sex: "U", tree: @tree).tap do |p|
      Event.create!(kind: "DEAT", eventable: p, tree: @tree)
    end

    visible = @tree.people.visible_to(nil)
    assert_not_includes visible, living
    assert_includes     visible, dead
  end

  # -----------------------------------------------------------------------
  # Graph node redaction
  # -----------------------------------------------------------------------

  test "node_data for a living person is redacted for a non-member" do
    Current.session = @outsider.sessions.create!
    person = Person.create!(given_names: "Alice", sex: "F", tree: @tree)
    node = person.send(:node_data, person, generation: 0, order: 0)

    assert_equal "Living", node[:name]
    assert_nil             node[:birth_year]
    assert_nil             node[:sex]
    assert                 node[:living]
  ensure
    Current.reset
  end

  test "node_data for a deceased person is NOT redacted for a non-member" do
    Current.session = @outsider.sessions.create!
    person = Person.create!(given_names: "Bob", sex: "M", tree: @tree)
    Event.create!(kind: "DEAT", eventable: person, tree: @tree)
    node = person.send(:node_data, person, generation: 0, order: 0)

    assert_equal "Bob", node[:name]
    assert_equal "M",   node[:sex]
    assert_nil          node[:living]
  ensure
    Current.reset
  end
end
