class ClanTreesController < ApplicationController
  include TreeGraphs

  CLAN_DEPTH = 8

  def show
    @root = Current.tree.root_person
    return unless @root

    @depth = CLAN_DEPTH
    if Current.tree.people.one?
      build_tree_graph @root, mode: "ancestors", depth: 1, ghosts: true
    else
      build_tree_graph @root, mode: "descendants", depth: @depth, ghosts: false
    end
  end
end
