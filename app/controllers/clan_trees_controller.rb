class ClanTreesController < ApplicationController
  include TreeGraphs

  CLAN_DEPTH = 8

  def show
    @root = Current.tree.root_person
    return unless @root

    @depth = CLAN_DEPTH
    build_tree_graph @root, mode: "descendants", depth: @depth, ghosts: false
  end
end
