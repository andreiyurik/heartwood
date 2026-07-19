require "test_helper"

class PersonSearchTest < ActiveSupport::TestCase
  setup do
    @tree   = trees(:alpha)
    @member = users(:one)
    @other  = trees(:beta)

    @bach   = Person.create!(given_names: "Johann", surname: "Bach",    sex: "M", tree: @tree)
    @handel = Person.create!(given_names: "Georg",  surname: "Handel",  sex: "M", tree: @tree)
    @clara  = Person.create!(given_names: "Clara",  surname: "Schumann", sex: "F", tree: @tree)
    # Make them deceased so they're visible to outsiders too
    [ @bach, @handel, @clara ].each do |p|
      Event.create!(kind: "DEAT", eventable: p, tree: @tree)
    end

    @living = Person.create!(given_names: "Alice", surname: "Living", sex: "F", tree: @tree)
  end

  # --- blank query returns all visible people ---

  test "blank query returns all visible people for member" do
    result = @tree.people.search("", user: @member)
    assert_includes result, @bach
    assert_includes result, @living
  end

  test "blank query hides living people from non-member" do
    result = @tree.people.search("", user: users(:two))
    assert_includes result, @bach
    assert_not_includes result, @living
  end

  # --- name matching ---

  test "matches given_names" do
    result = @tree.people.search("Johann", user: @member)
    assert_includes     result, @bach
    assert_not_includes result, @handel
  end

  test "matches surname" do
    result = @tree.people.search("Handel", user: @member)
    assert_includes     result, @handel
    assert_not_includes result, @bach
  end

  test "search is case-insensitive" do
    result = @tree.people.search("handel", user: @member)
    assert_includes result, @handel
  end

  test "multi-word query ANDs terms" do
    result = @tree.people.search("Johann Bach", user: @member)
    assert_includes     result, @bach
    assert_not_includes result, @handel
  end

  test "partial match works (prefix)" do
    result = @tree.people.search("Schu", user: @member)
    assert_includes result, @clara
  end

  test "no match returns empty" do
    result = @tree.people.search("Beethoven", user: @member)
    assert_empty result
  end

  # --- tree scoping ---

  test "search is tree-scoped (does not return other tree's people)" do
    other_person = Person.create!(given_names: "Johann", surname: "Strauss",
                                  sex: "M", tree: @other)
    Event.create!(kind: "DEAT", eventable: other_person, tree: @other)

    result = @tree.people.search("Johann", user: @member)
    assert_not_includes result, other_person
  end

  # --- sex filter composability ---

  test "search chains with sex filter" do
    males   = @tree.people.search("", user: @member).where(sex: "M")
    females = @tree.people.search("", user: @member).where(sex: "F")

    assert_includes     males,   @bach
    assert_not_includes males,   @clara
    assert_includes     females, @clara
  end
end
