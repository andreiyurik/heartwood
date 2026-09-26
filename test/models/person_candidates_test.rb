require "test_helper"

class PersonCandidatesTest < ActiveSupport::TestCase
  setup { @sebastian = people(:johann_sebastian) }

  test "matches by name within the tree, never the person themselves" do
    names = @sebastian.relative_candidates("bach", user: users(:bach)).map(&:display_name)

    assert_not_includes names, @sebastian.display_name
    assert_includes names, people(:wilhelm_friedemann).display_name
  end

  test "leaves out people already in the given relation" do
    candidates = @sebastian.relative_candidates("bach", relation: "child", user: users(:bach))

    assert_not_includes candidates, people(:wilhelm_friedemann)
    assert_includes candidates, people(:ambrosius)
  end

  test "without a relation only the person is excluded" do
    assert_includes @sebastian.relative_candidates("bach", user: users(:bach)), people(:ambrosius)
  end

  test "a blank query finds nobody" do
    assert_empty @sebastian.relative_candidates("  ", user: users(:bach))
  end

  test "never crosses into another tree" do
    Person.create!(given_names: "Bach", surname: "Foreigner", tree: trees(:beta))

    assert_empty @sebastian.relative_candidates("Foreigner", user: users(:bach))
  end

  test "caps the list at eight" do
    9.times { |n| Person.create!(given_names: "Extra#{n}", surname: "Bach", tree: trees(:bach)) }

    assert_equal 8, @sebastian.relative_candidates("Extra", user: users(:bach)).size
  end
end
