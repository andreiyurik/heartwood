require "test_helper"

# Adding relatives — the domain operations behind the "add parent/child/partner"
# UI. They resolve the right Family record so kinship stays derived through it.
# See docs/domain/family.md, docs/domain/relationship.md.
class PersonRelativesTest < ActiveSupport::TestCase
  setup do
    Current.tree = trees(:alpha)
    @p = Person.create!(given_names: "Pat", surname: "Root", sex: "U", tree: Current.tree)
  end

  teardown { Current.reset }

  test "add_parent links a new parent through the person's birth family" do
    mother = @p.add_parent(given_names: "Mary", surname: "Root", sex: "F")
    assert_includes @p.parents, mother
    assert_includes mother.children, @p
  end

  test "two added parents share one family and become partners" do
    mother = @p.add_parent(given_names: "Mary", sex: "F")
    father = @p.add_parent(given_names: "Mark", sex: "M")
    assert_equal [ mother, father ].to_set, @p.parents.to_set
    assert_includes mother.partners, father
  end

  test "add_child links a new child and makes the person their parent" do
    child = @p.add_child(given_names: "Kim", surname: "Root", sex: "U")
    assert_includes @p.children, child
    assert_includes child.parents, @p
  end

  test "two added children become siblings" do
    a = @p.add_child(given_names: "A")
    b = @p.add_child(given_names: "B")
    assert_includes a.siblings, b
  end

  test "add_partner creates a union and is reciprocal" do
    spouse = @p.add_partner(given_names: "Sam", sex: "M")
    assert_includes @p.partners, spouse
    assert_includes spouse.partners, @p
  end

  test "a child added after a partner has both parents" do
    spouse = @p.add_partner(given_names: "Sam", sex: "M")
    child = @p.add_child(given_names: "Kid")
    assert_equal [ @p, spouse ].to_set, child.parents.to_set
  end

  test "returns the created relative" do
    rel = @p.add_child(given_names: "Returned")
    assert_kind_of Person, rel
    assert rel.persisted?
    assert_equal "Returned", rel.given_names
  end

  test "created relatives belong to Current.tree" do
    parent = @p.add_parent(given_names: "Parent", sex: "F")
    assert_equal Current.tree, parent.tree
  end
end
