require "test_helper"

class Person::TreeGraphTest < ActiveSupport::TestCase
  setup do
    @tree   = trees(:alpha)
    @child  = Person.create!(sex: "U", tree: @tree)
    @father = Person.create!(sex: "M", tree: @tree)
    @mother = Person.create!(sex: "F", tree: @tree)
    fam = Family.create!(tree: @tree)
    fam.partners << @father << @mother
    fam.children << @child
    @viewer = users(:one)
  end

  # --- ancestor_graph ---

  test "ancestor_graph for isolated person has only the focus node" do
    loner = Person.create!(sex: "U", tree: @tree)
    graph = ancestors_of(loner, ghosts: false)   # traversal semantics, sans add-slots
    assert_equal 1, graph[:nodes].size
    assert_empty  graph[:edges]
    assert_equal  loner.id, graph[:focus_id]
    assert_equal  "ancestors", graph[:mode]
  end

  test "ancestor_graph includes parents at generation 1" do
    graph = ancestors_of(@child, depth: 1)
    ids = graph[:nodes].map { |n| n[:id] }
    assert_includes ids, @child.id
    assert_includes ids, @father.id
    assert_includes ids, @mother.id
  end

  test "ancestor_graph edges go from child to parent" do
    graph = ancestors_of(@child, depth: 1)
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

    graph = ancestors_of(@child, depth: 1)
    assert_not_includes graph[:nodes].map { |n| n[:id] }, grandpa.id

    graph = ancestors_of(@child, depth: 2)
    assert_includes graph[:nodes].map { |n| n[:id] }, grandpa.id
  end

  test "ancestor_graph nodes carry generation and order" do
    graph = ancestors_of(@child, depth: 1)

    focus = graph[:nodes].find { |n| n[:id] == @child.id }
    assert_equal 0, focus[:generation]
    assert_equal 0, focus[:order]

    parent_nodes = graph[:nodes].select { |n| n[:generation] == 1 }
    assert_equal 2, parent_nodes.size
    assert_equal [ 0, 1 ], parent_nodes.map { |n| n[:order] }.sort
  end

  test "ancestor_graph nodes carry name and sex" do
    graph = ancestors_of(@child, depth: 1)
    focus = graph[:nodes].find { |n| n[:id] == @child.id }
    assert_equal @child.display_name, focus[:name]
    assert_equal @child.sex,          focus[:sex]
  end

  test "nodes carry the given/surname split for the two-line card" do
    named = Person.create!(given_names: "Johann Sebastian", surname: "Bach", sex: "M", tree: @tree)
    node  = node_for(named)
    assert_equal "Johann Sebastian", node[:given]
    assert_equal "Bach",             node[:surname]
  end

  test "nodes carry the partnered flag that picks the card or circle shape" do
    graph = ancestors_of(@child, depth: 1)
    by_id = graph[:nodes].index_by { |n| n[:id] }
    assert by_id[@father.id][:partnered], "couple member should be partnered"
    assert by_id[@mother.id][:partnered], "couple member should be partnered"
    assert_not by_id[@child.id][:partnered], "single should not be partnered"
  end

  test "nodes carry a compact lifespan string" do
    dated = Person.create!(given_names: "Dated", sex: "M", tree: @tree)
    Event.create!(kind: "BIRT", eventable: dated, tree: @tree, date_raw: "23 MAY 1767", date_start: Date.new(1767, 5, 23))
    Event.create!(kind: "DEAT", eventable: dated, tree: @tree, date_raw: "1837", date_start: Date.new(1837, 1, 1))
    node = node_for(dated)
    assert_equal "1767 – 1837", node[:years]
  end

  test "lifespan falls back to the raw date string when the date did not parse" do
    approx = Person.create!(given_names: "Approx", sex: "M", tree: @tree)
    Event.create!(kind: "BIRT", eventable: approx, tree: @tree, date_raw: "ок. 1696")
    Event.create!(kind: "DEAT", eventable: approx, tree: @tree)
    node = node_for(approx)
    assert_equal "ок. 1696", node[:years]
  end

  # --- ghost add-relative slots ---

  test "ancestor_graph adds an add-parent ghost above ancestors with no parents" do
    graph  = ancestors_of(@child, depth: 2)
    ghosts = graph[:nodes].select { |n| n[:ghost] }
    assert_equal %w[parent parent], ghosts.map { |n| n[:ghost] }
    assert_equal [ @father.id, @mother.id ].sort, ghosts.map { |n| n[:ghost_for] }.sort
    assert ghosts.all? { |n| n[:id].negative? }, "ghost ids must never collide with people"
  end

  test "no parent ghost when the frontier is cut by depth" do
    graph = ancestors_of(@child, depth: 1)
    assert_empty graph[:nodes].select { |n| n[:ghost] }
  end

  test "descendant_graph adds partner and child ghosts for a single focus" do
    loner = Person.create!(sex: "M", tree: @tree)
    graph = descendants_of(loner, depth: 2)
    ghosts = graph[:nodes].select { |n| n[:ghost] }
    assert_equal %w[child partner], ghosts.map { |n| n[:ghost] }.sort
    partner_ghost = ghosts.find { |n| n[:ghost] == "partner" }
    assert partner_ghost[:partnered], "partner ghost should render as the couple's second card"
  end

  test "no partner ghost when the focus couple is already shown" do
    graph = descendants_of(@father, depth: 1)
    assert_equal %w[child], graph[:nodes].select { |n| n[:ghost] }.map { |n| n[:ghost] }
  end

  test "ghosts are not added for viewers outside the tree" do
    @viewer = users(:two)
    graph = ancestors_of(@child, depth: 2)
    assert_empty graph[:nodes].select { |n| n[:ghost] }
  end

  test "ghosts can be disabled explicitly" do
    graph = ancestors_of(@child, depth: 2, ghosts: false)
    assert_empty graph[:nodes].select { |n| n[:ghost] }
  end

  test "redacted living node carries no given or surname" do
    @viewer = users(:two)
    living = Person.create!(given_names: "Eve", surname: "Hidden", sex: "F", tree: @tree)
    node   = node_for(living)
    assert node[:living]
    assert_nil node[:given]
    assert_nil node[:surname]
  end

  test "ancestor_graph does not revisit the same person twice" do
    # father is both in @child's family and is its own parent (corner case via separate fam)
    self_fam = Family.create!(tree: @tree)
    self_fam.partners << @father
    self_fam.children << @father  # contrived but should not loop
    graph = ancestors_of(@child, depth: 10)
    ids = graph[:nodes].map { |n| n[:id] }
    assert_equal ids.uniq, ids
  end

  # --- descendant_graph ---

  test "descendant_graph for person with no children has only the focus node" do
    loner = Person.create!(sex: "U", tree: @tree)
    graph = descendants_of(loner, ghosts: false)   # traversal semantics, sans add-slots
    assert_equal 1,             graph[:nodes].size
    assert_empty                graph[:edges]
    assert_equal "descendants", graph[:mode]
  end

  test "descendant_graph includes child at generation 1" do
    graph = descendants_of(@father, depth: 1)
    ids = graph[:nodes].map { |n| n[:id] }
    assert_includes ids, @father.id
    assert_includes ids, @child.id
  end

  test "descendant_graph edges go from parent to child" do
    graph = descendants_of(@father, depth: 1)
    edge = graph[:edges].find { |e| e[:from_id] == @father.id }
    assert_not_nil edge
    assert_equal @child.id, edge[:to_id]
  end

  test "descendant_graph respects depth: stops at the given generation" do
    grandchild = Person.create!(sex: "U", tree: @tree)
    gc_fam = Family.create!(tree: @tree)
    gc_fam.partners << @child
    gc_fam.children << grandchild

    graph = descendants_of(@father, depth: 1)
    assert_not_includes graph[:nodes].map { |n| n[:id] }, grandchild.id

    graph = descendants_of(@father, depth: 2)
    assert_includes graph[:nodes].map { |n| n[:id] }, grandchild.id
  end

  # --- persons hash ---

  test "ancestor_graph includes a :persons hash keyed by person id" do
    graph = ancestors_of(@child, depth: 1)
    assert_kind_of Hash, graph[:persons]
    assert_equal @child, graph[:persons][@child.id]
  end

  # --- avatar in node (0.3 photo-in-node) ---

  test "node carries avatar_url when an avatar is attached" do
    attach_avatar(@child)
    graph = ancestors_of(@child, depth: 1)
    focus = graph[:nodes].find { |n| n[:id] == @child.id }
    assert focus.key?(:avatar_url), "node should expose :avatar_url"
    assert focus[:avatar_url].present?, "attached avatar should yield a url"
  end

  test "node avatar_url is nil when no avatar is attached" do
    graph = ancestors_of(@child, depth: 1)
    focus = graph[:nodes].find { |n| n[:id] == @child.id }
    assert_nil focus[:avatar_url]
  end

  test "redacted living person never leaks an avatar_url" do
    outsider = users(:two)   # owns tree :beta, not :alpha
    @viewer = outsider
    living = Person.create!(given_names: "Eve", sex: "F", tree: @tree)
    attach_avatar(living)

    node = node_for(living)
    assert node[:living]
    assert_nil node[:avatar_url]
  end

  # --- unions (couples) ---

  test "ancestor_graph pairs both parents into one union over the child" do
    graph = ancestors_of(@child, depth: 1)
    assert_equal 1, graph[:unions].size
    union = graph[:unions].first
    assert_equal [ @father.id, @mother.id ].sort, union[:partner_ids].sort
    assert_equal [ @child.id ], union[:child_ids]
  end

  test "descendant_graph surfaces the married-in spouse as a partner" do
    # @father's children come through his family with @mother; @mother is not a
    # blood descendant, so she must be pulled in and paired with him.
    graph = descendants_of(@father, depth: 1)
    ids = graph[:nodes].map { |n| n[:id] }
    assert_includes ids, @mother.id, "spouse who married in should appear"

    assert_equal 1, graph[:unions].size
    union = graph[:unions].first
    assert_equal [ @father.id, @mother.id ].sort, union[:partner_ids].sort
    assert_equal [ @child.id ], union[:child_ids]
  end

  test "married-in spouse sits at the same generation as their partner" do
    graph  = descendants_of(@father, depth: 1)
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

    graph = descendants_of(solo, depth: 1, ghosts: false)
    assert_empty graph[:unions]
    assert_equal [ solo.id, kid.id ].sort, graph[:nodes].map { |n| n[:id] }.sort
  end

  test "a living married-in spouse is redacted but still paired" do
    outsider = users(:two)   # not a member of tree :alpha
    @viewer = outsider

    dad  = Person.create!(given_names: "Dad", sex: "M", tree: @tree)
    mom  = Person.create!(given_names: "Mom", sex: "F", tree: @tree)   # no death → living
    kid  = Person.create!(given_names: "Kid", sex: "U", tree: @tree)
    Event.create!(kind: "DEAT", eventable: dad, tree: @tree)
    Event.create!(kind: "DEAT", eventable: kid, tree: @tree)
    fam = Family.create!(tree: @tree)
    fam.partners << dad << mom
    fam.children << kid

    graph    = descendants_of(dad, depth: 1)
    mom_node = graph[:nodes].find { |n| n[:id] == mom.id }
    assert mom_node[:living], "living spouse must be redacted"
    assert_includes graph[:unions].first[:partner_ids], mom.id
  end

  test "unions only reference people inside the current tree scope" do
    graph    = ancestors_of(@child, depth: 2)
    node_ids = graph[:nodes].map { |n| n[:id] }.to_set
    graph[:unions].each do |union|
      assert (union[:partner_ids] + union[:child_ids]).all? { |id| node_ids.include?(id) },
        "a union must not reference anyone outside the traversed (tree-scoped) graph"
    end
  end

  private

  def ancestors_of(person, **options)
    graph_for(person, "ancestors", **options)
  end

  def descendants_of(person, **options)
    graph_for(person, "descendants", **options)
  end

  def graph_for(person, mode, depth: 4, ghosts: true)
    Person::TreeGraph.new(person, mode:, depth:, ghosts:, viewer: @viewer,
                          avatar_url: ->(avatar) { "/avatars/#{avatar.blob.id}" }).build
  end

  def node_for(person)
    ancestors_of(person, depth: 0, ghosts: false)[:nodes].first
  end

  def attach_avatar(person)
    png = StringIO.new("\x89PNG\r\n\x1a\n" + "\x00" * 100)
    person.avatar.attach(io: png, filename: "a.png", content_type: "image/png")
  end
end
