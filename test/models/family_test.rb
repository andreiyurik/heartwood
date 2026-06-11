require "test_helper"

# Family (FAM) + derived relationships — see docs/domain/family.md,
# docs/domain/relationship.md, docs/domain/domain-model.md.
#
# Graph under test:
#   John + Jane  -> children: Joe, Mary   (Joe & Mary are siblings)
#   Joe  + Lucy  -> child:    Tim
class FamilyTest < ActiveSupport::TestCase
  setup do
    @tree = trees(:alpha)
    @john = Person.create!(given_names: "John", surname: "Doe", sex: "M", tree: @tree)
    @jane = Person.create!(given_names: "Jane", surname: "Doe", sex: "F", tree: @tree)
    @joe  = Person.create!(given_names: "Joe",  surname: "Doe", sex: "M", tree: @tree)
    @mary = Person.create!(given_names: "Mary", surname: "Doe", sex: "F", tree: @tree)
    @lucy = Person.create!(given_names: "Lucy", surname: "Roe", sex: "F", tree: @tree)
    @tim  = Person.create!(given_names: "Tim",  surname: "Doe", sex: "M", tree: @tree)

    @f1 = Family.create!(tree: @tree)
    @f1.partners << [ @john, @jane ]
    @f1.children << [ @joe, @mary ]

    @f2 = Family.create!(tree: @tree)
    @f2.partners << [ @joe, @lucy ]
    @f2.children << @tim
  end

  test "a family links partners and children" do
    assert_equal [ @john, @jane ].to_set, @f1.partners.to_set
    assert_equal [ @joe, @mary ].to_set, @f1.children.to_set
  end

  test "parents are derived through the family a person is a child of" do
    assert_equal [ @john, @jane ].to_set, @joe.parents.to_set
    assert_empty @john.parents
  end

  test "children are derived through families a person partners in" do
    assert_equal [ @joe, @mary ].to_set, @john.children.to_set
    assert_equal [ @tim ], @joe.children.to_a
  end

  test "siblings are the other children of the same parents" do
    assert_equal [ @mary ], @joe.siblings.to_a
    assert_empty @tim.siblings
  end

  test "partners are co-partners in the same family, excluding self" do
    assert_equal [ @jane ], @john.partners.to_a
    assert_equal [ @lucy ].to_set, @joe.partners.to_set
  end

  test "a person can be both a child and a partner (Joe)" do
    assert_includes @joe.parents, @john
    assert_includes @joe.children, @tim
  end
end
