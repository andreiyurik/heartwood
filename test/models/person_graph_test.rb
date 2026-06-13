require "test_helper"

class PersonGraphTest < ActiveSupport::TestCase
  setup do
    @tree   = trees(:alpha)
    @child  = Person.create!(sex: "U", tree: @tree)
    @father = Person.create!(sex: "M", tree: @tree)
    @mother = Person.create!(sex: "F", tree: @tree)
    fam = Family.create!(tree: @tree)
    fam.partners << @father << @mother
    fam.children << @child
    Current.session = users(:one).sessions.create!
  end

  teardown { Current.reset }

  # --- ancestor_graph ---

  test "ancestor_graph for isolated person has only the focus node" do
    loner = Person.create!(sex: "U", tree: @tree)
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
    assert_equal [ @child.id, @child.id ], from_ids.sort
    assert_includes to_ids, @father.id
    assert_includes to_ids, @mother.id
  end

  test "ancestor_graph respects depth: stops at the given generation" do
    grandpa  = Person.create!(sex: "M", tree: @tree)
    gran_fam = Family.create!(tree: @tree)
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
    assert_equal [ 0, 1 ], parent_nodes.map { |n| n[:order] }.sort
  end

  test "ancestor_graph nodes carry name and sex" do
    graph = @child.ancestor_graph(depth: 1)
    focus = graph[:nodes].find { |n| n[:id] == @child.id }
    assert_equal @child.display_name, focus[:name]
    assert_equal @child.sex,          focus[:sex]
  end

  test "ancestor_graph does not revisit the same person twice" do
    # father is both in @child's family and is its own parent (corner case via separate fam)
    self_fam = Family.create!(tree: @tree)
    self_fam.partners << @father
    self_fam.children << @father  # contrived but should not loop
    graph = @child.ancestor_graph(depth: 10)
    ids = graph[:nodes].map { |n| n[:id] }
    assert_equal ids.uniq, ids
  end

  # --- descendant_graph ---

  test "descendant_graph for person with no children has only the focus node" do
    loner = Person.create!(sex: "U", tree: @tree)
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
    grandchild = Person.create!(sex: "U", tree: @tree)
    gc_fam = Family.create!(tree: @tree)
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

  # --- avatar in node (0.3 photo-in-node) ---

  test "node carries avatar_url when an avatar is attached" do
    attach_avatar(@child)
    graph = @child.ancestor_graph(depth: 1)
    focus = graph[:nodes].find { |n| n[:id] == @child.id }
    assert focus.key?(:avatar_url), "node should expose :avatar_url"
    assert focus[:avatar_url].present?, "attached avatar should yield a url"
  end

  test "node avatar_url is nil when no avatar is attached" do
    graph = @child.ancestor_graph(depth: 1)
    focus = graph[:nodes].find { |n| n[:id] == @child.id }
    assert_nil focus[:avatar_url]
  end

  test "redacted living person never leaks an avatar_url" do
    Current.reset
    outsider = users(:two)   # owns tree :beta, not :alpha
    Current.session = outsider.sessions.create!
    living = Person.create!(given_names: "Eve", sex: "F", tree: @tree)
    attach_avatar(living)

    node = living.send(:node_data, living, generation: 0, order: 0)
    assert node[:living]
    assert_nil node[:avatar_url]
  end

  # --- unions (couples) ---

  test "ancestor_graph pairs both parents into one union over the child" do
    graph = @child.ancestor_graph(depth: 1)
    assert_equal 1, graph[:unions].size
    union = graph[:unions].first
    assert_equal [ @father.id, @mother.id ].sort, union[:partner_ids].sort
    assert_equal [ @child.id ], union[:child_ids]
  end

  test "descendant_graph surfaces the married-in spouse as a partner" do
    # @father's children come through his family with @mother; @mother is not a
    # blood descendant, so she must be pulled in and paired with him.
    graph = @father.descendant_graph(depth: 1)
    ids = graph[:nodes].map { |n| n[:id] }
    assert_includes ids, @mother.id, "spouse who married in should appear"

    assert_equal 1, graph[:unions].size
    union = graph[:unions].first
    assert_equal [ @father.id, @mother.id ].sort, union[:partner_ids].sort
    assert_equal [ @child.id ], union[:child_ids]
  end

  test "married-in spouse sits at the same generation as their partner" do
    graph  = @father.descendant_graph(depth: 1)
    father = graph[:nodes].find { |n| n[:id] == @father.id }
    mother = graph[:nodes].find { |n| n[:id] == @mother.id }
    assert_equal father[:generation], mother[:generation]
  end

  test "a single parent yields no union (no phantom partner)" do
    solo  = Person.create!(sex: "F", tree: @tree)
    kid   = Person.create!(sex: "U", tree: @tree)
    fam   = Family.create!(tree: @tree)
    fam.partners << solo
    fam.children << kid

    graph = solo.descendant_graph(depth: 1)
    assert_empty graph[:unions]
    assert_equal [ solo.id, kid.id ].sort, graph[:nodes].map { |n| n[:id] }.sort
  end

  test "a living married-in spouse is redacted but still paired" do
    Current.reset
    outsider = users(:two)   # not a member of tree :alpha
    Current.session = outsider.sessions.create!

    dad  = Person.create!(given_names: "Dad", sex: "M", tree: @tree)
    mom  = Person.create!(given_names: "Mom", sex: "F", tree: @tree)   # no death → living
    kid  = Person.create!(given_names: "Kid", sex: "U", tree: @tree)
    Event.create!(kind: "DEAT", eventable: dad, tree: @tree)
    Event.create!(kind: "DEAT", eventable: kid, tree: @tree)
    fam = Family.create!(tree: @tree)
    fam.partners << dad << mom
    fam.children << kid

    graph    = dad.descendant_graph(depth: 1)
    mom_node = graph[:nodes].find { |n| n[:id] == mom.id }
    assert mom_node[:living], "living spouse must be redacted"
    assert_includes graph[:unions].first[:partner_ids], mom.id
  end

  test "unions only reference people inside the current tree scope" do
    graph    = @child.ancestor_graph(depth: 2)
    node_ids = graph[:nodes].map { |n| n[:id] }.to_set
    graph[:unions].each do |union|
      assert (union[:partner_ids] + union[:child_ids]).all? { |id| node_ids.include?(id) },
        "a union must not reference anyone outside the traversed (tree-scoped) graph"
    end
  end

  private

  def attach_avatar(person)
    png = StringIO.new("\x89PNG\r\n\x1a\n" + "\x00" * 100)
    person.avatar.attach(io: png, filename: "a.png", content_type: "image/png")
  end
end
