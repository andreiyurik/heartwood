class TreesController < ApplicationController
  include PersonScoped, TreeGraphs

  def show
    @depth = depth_param
    build_tree_graph @person, mode: params[:mode].presence_in(%w[ancestors descendants]) || "ancestors", depth: @depth
  end

  private

  def depth_param
    [ [ params.fetch(:depth, 4).to_i, 0 ].max, 6 ].min
  end
end
