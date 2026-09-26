class ClanTreesController < ApplicationController
  CLAN_DEPTH = 8

  def show
    @root = Current.tree.root_person
    return unless @root

    @depth   = CLAN_DEPTH
    result   = @root.descendant_graph(depth: @depth, ghosts: false)
    @mode    = result[:mode]
    @graph   = result.except(:persons)
    @persons = result[:persons]
  end
end
