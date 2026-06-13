require "test_helper"

# The relationship calculator: naming how two people in one tree are related by
# traversing the Family graph to a lowest common ancestor. See relationship.md.
class PersonRelationshipTest < ActiveSupport::TestCase
  setup { Current.tree = trees(:alpha) }
  teardown { Current.reset }

  def person(attrs = {})
    Person.create!({ sex: "U", tree: Current.tree }.merge(attrs))
  end

  test "parent and child, gendered both ways" do
    child  = person(sex: "M")
    mother = child.add_parent(given_names: "Mary", sex: "F")
    assert_equal "mother", child.relationship_to(mother)
    assert_equal "son",    mother.relationship_to(child)
  end

  test "grandparent and grandchild" do
    child       = person(sex: "F")
    parent      = child.add_parent(sex: "M")
    grandmother = parent.add_parent(sex: "F")
    assert_equal "grandmother",   child.relationship_to(grandmother)
    assert_equal "granddaughter", grandmother.relationship_to(child)
  end

  test "great-grandparent composes the great- prefix" do
    child = person
    p     = child.add_parent(sex: "M")
    gp    = p.add_parent(sex: "M")
    ggp   = gp.add_parent(sex: "F")
    assert_equal "great-grandmother", child.relationship_to(ggp)
  end

  test "siblings" do
    a = person(sex: "M")
    a.add_parent(sex: "F")
    b = a.parents.first.add_child(sex: "F")
    assert_equal "sister",  a.relationship_to(b)
    assert_equal "brother", b.relationship_to(a)
  end

  test "spouse via partnership, not ancestry" do
    a = person(sex: "M")
    b = a.add_partner(sex: "F")
    assert_equal "wife",    a.relationship_to(b)
    assert_equal "husband", b.relationship_to(a)
  end

  test "aunt and nephew" do
    grandparent = person(sex: "F")
    parent      = grandparent.add_child(sex: "M")
    aunt        = grandparent.add_child(sex: "F")
    child       = parent.add_child(sex: "M")
    assert_equal "aunt",    child.relationship_to(aunt)
    assert_equal "nephew",  aunt.relationship_to(child)
  end

  test "first cousins" do
    grandparent = person
    p1 = grandparent.add_child(sex: "M")
    p2 = grandparent.add_child(sex: "F")
    c1 = p1.add_child(sex: "M")
    c2 = p2.add_child(sex: "F")
    assert_equal "first cousin", c1.relationship_to(c2)
  end

  test "first cousin once removed (the triple-distance case)" do
    grandparent = person
    p1 = grandparent.add_child(sex: "M")
    p2 = grandparent.add_child(sex: "F")
    c1 = p1.add_child(sex: "M")
    c2 = p2.add_child(sex: "F")
    grandchild = c2.add_child(sex: "M")
    assert_equal "first cousin once removed", c1.relationship_to(grandchild)
  end

  test "second cousins" do
    ggp = person
    g1  = ggp.add_child(sex: "M")
    g2  = ggp.add_child(sex: "F")
    c1  = g1.add_child(sex: "M").add_child(sex: "M")
    c2  = g2.add_child(sex: "F").add_child(sex: "F")
    assert_equal "second cousin", c1.relationship_to(c2)
  end

  test "unrelated people in the same tree have no relationship" do
    assert_nil person.relationship_to(person)
  end

  test "people in different trees are never related" do
    other = Person.create!(sex: "U", tree: trees(:beta))
    assert_nil person.relationship_to(other)
  end

  test "a person has no relationship to themselves" do
    a = person
    assert_nil a.relationship_to(a)
  end

  test "Russian locale names relationships too" do
    I18n.with_locale(:ru) do
      child  = person(sex: "M")
      mother = child.add_parent(sex: "F")
      assert_equal "мать", child.relationship_to(mother)
    end
  end
end
