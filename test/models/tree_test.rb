require "test_helper"

class TreeTest < ActiveSupport::TestCase
  test "requires a name" do
    tree = Tree.new
    assert_not tree.valid?
    assert tree.errors[:name].any?
  end

  test "is valid with a name" do
    assert Tree.new(name: "My Tree").valid?
  end

  test "has many people" do
    tree = trees(:alpha)
    person = Person.create!(sex: "U", tree: tree)
    assert_includes tree.people, person
  end

  test "has many users through tree_memberships" do
    assert_includes trees(:alpha).users, users(:one)
  end

  test "destroying a tree destroys its people" do
    tree = Tree.create!(name: "Temp")
    Person.create!(sex: "U", tree: tree)
    assert_difference "Person.count", -1 do
      tree.destroy
    end
  end
end
