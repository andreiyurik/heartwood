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

  # --- root_person (progenitor of the родовое древо) ---

  test "root_person is nil for an empty tree" do
    assert_nil Tree.create!(name: "Empty").root_person
  end

  test "root_person picks the parentless ancestor with the most descendants" do
    tree = Tree.create!(name: "Clan")
    founder = Person.create!(given_names: "Founder", sex: "M", tree: tree)
    child   = Person.create!(given_names: "Child",   sex: "F", tree: tree)
    grandkid = Person.create!(given_names: "Grand",  sex: "U", tree: tree)
    f1 = Family.create!(tree: tree); f1.partners << founder; f1.children << child
    f2 = Family.create!(tree: tree); f2.partners << child;   f2.children << grandkid

    # A lone parentless person with no descendants must not outrank the founder.
    Person.create!(given_names: "Loner", sex: "U", tree: tree)

    assert_equal founder, tree.root_person
  end

  test "root_person stays within the tree (no cross-tree leak)" do
    tree  = Tree.create!(name: "Mine")
    mine  = Person.create!(given_names: "Mine", sex: "M", tree: tree)
    Person.create!(given_names: "Theirs", sex: "M", tree: trees(:beta))

    assert_equal mine, tree.root_person
  end

  test "descendant_count counts distinct descendants" do
    tree = Tree.create!(name: "Counts")
    a = Person.create!(sex: "M", tree: tree)
    b = Person.create!(sex: "F", tree: tree)
    c = Person.create!(sex: "U", tree: tree)
    f1 = Family.create!(tree: tree); f1.partners << a; f1.children << b
    f2 = Family.create!(tree: tree); f2.partners << b; f2.children << c

    assert_equal 2, a.descendant_count
    assert_equal 0, c.descendant_count
  end

  test "destroying a tree destroys its people" do
    tree = Tree.create!(name: "Temp")
    Person.create!(sex: "U", tree: tree)
    assert_difference "Person.count", -1 do
      tree.destroy
    end
  end

  test "destroying a tree cascades to its families, events and sources" do
    tree   = Tree.create!(name: "Temp Cascade")
    person = Person.create!(sex: "U", tree: tree)
    Family.create!(tree: tree)
    Event.create!(kind: "BIRT", eventable: person, tree: tree)
    Source.create!(title: "Parish register", tree: tree)

    assert_difference [ "Family.count", "Event.count", "Source.count" ], -1 do
      tree.destroy
    end
  end
end
