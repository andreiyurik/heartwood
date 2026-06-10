require "test_helper"

class PersonGraphTest < ActiveSupport::TestCase
  setup do
    @child  = Person.create!(sex: "U")
    @father = Person.create!(sex: "M")
    @mother = Person.create!(sex: "F")
    fam = Family.create!
    fam.partners << @father << @mother
    fam.children << @child
  end

  # --- ancestor_graph ---

  test "ancestor_graph for isolated person has only the focus node" do
    loner = Person.create!(sex: "U")
    graph = loner.ancestor_graph
    assert_equal 1, graph[:nodes].size
    assert_empty  graph[:edges]
    assert_equal  loner.id, graph[:focus_id]
    assert_equal  "ancestors", graph[:mode]
  end

  test "ancestor_graph includes parents at generation 1" do
    graph = @child.ancestor_graph(depth: 1)
    ids = graph[:nodes].map { |n| n[:id] }
    assert_includes ids, @child.id
    assert_includes ids, @father.id
    assert_includes ids, @mother.id
  end

  test "ancestor_graph edges go from child to parent" do
    graph = @child.ancestor_graph(depth: 1)
    from_ids = graph[:edges].map { |e| e[:from_id] }
    to_ids   = graph[:edges].map { |e| e[:to_id] }
    assert_equal [@child.id, @child.id], from_ids.sort
    assert_includes to_ids, @father.id
    assert_includes to_ids, @mother.id
  end

  test "ancestor_graph respects depth: stops at the given generation" do
    grandpa = Person.create!(sex: "M")
    gran_fam = Family.create!
    gran_fam.partners << grandpa
    gran_fam.children << @father

    graph = @child.ancestor_graph(depth: 1)
    assert_not_includes graph[:nodes].map { |n| n[:id] }, grandpa.id

    graph = @child.ancestor_graph(depth: 2)
    assert_includes graph[:nodes].map { |n| n[:id] }, grandpa.id
  end

  test "ancestor_graph nodes carry generation and order" do
    graph = @child.ancestor_graph(depth: 1)

    focus = graph[:nodes].find { |n| n[:id] == @child.id }
    assert_equal 0, focus[:generation]
    assert_equal 0, focus[:order]

    parent_nodes = graph[:nodes].select { |n| n[:generation] == 1 }
    assert_equal 2, parent_nodes.size
    assert_equal [0, 1], parent_nodes.map { |n| n[:order] }.sort
  end

  test "ancestor_graph nodes carry name and sex" do
    graph = @child.ancestor_graph(depth: 1)
    focus = graph[:nodes].find { |n| n[:id] == @child.id }
    assert_equal @child.display_name, focus[:name]
    assert_equal @child.sex,          focus[:sex]
  end

  test "ancestor_graph does not revisit the same person twice" do
    # father is both in @child's family and is its own parent (corner case via separate fam)
    self_fam = Family.create!
    self_fam.partners << @father
    self_fam.children << @father  # contrived but should not loop
    graph = @child.ancestor_graph(depth: 10)
    ids = graph[:nodes].map { |n| n[:id] }
    assert_equal ids.uniq, ids
  end

  # --- descendant_graph ---

  test "descendant_graph for person with no children has only the focus node" do
    loner = Person.create!(sex: "U")
    graph = loner.descendant_graph
    assert_equal 1,             graph[:nodes].size
    assert_empty                graph[:edges]
    assert_equal "descendants", graph[:mode]
  end

  test "descendant_graph includes child at generation 1" do
    graph = @father.descendant_graph(depth: 1)
    ids = graph[:nodes].map { |n| n[:id] }
    assert_includes ids, @father.id
    assert_includes ids, @child.id
  end

  test "descendant_graph edges go from parent to child" do
    graph = @father.descendant_graph(depth: 1)
    edge = graph[:edges].find { |e| e[:from_id] == @father.id }
    assert_not_nil edge
    assert_equal @child.id, edge[:to_id]
  end

  test "descendant_graph respects depth: stops at the given generation" do
    grandchild = Person.create!(sex: "U")
    gc_fam = Family.create!
    gc_fam.partners << @child
    gc_fam.children << grandchild

    graph = @father.descendant_graph(depth: 1)
    assert_not_includes graph[:nodes].map { |n| n[:id] }, grandchild.id

    graph = @father.descendant_graph(depth: 2)
    assert_includes graph[:nodes].map { |n| n[:id] }, grandchild.id
  end

  # --- persons hash ---

  test "ancestor_graph includes a :persons hash keyed by person id" do
    graph = @child.ancestor_graph(depth: 1)
    assert_kind_of Hash, graph[:persons]
    assert_equal @child, graph[:persons][@child.id]
  end
end
