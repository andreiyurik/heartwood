class TreesController < ApplicationController
  before_action :find_person

  def show
    @depth  = depth_param
    result  = params[:mode] == "descendants" ?
                @person.descendant_graph(depth: @depth) :
                @person.ancestor_graph(depth: @depth)
    @mode    = result[:mode]
    @graph   = result.except(:persons)
    @persons = result[:persons]
  end

  private

  def find_person
    @person = Current.tree.people.find(params[:person_id])
  end

  def depth_param
    [ [ params.fetch(:depth, 4).to_i, 0 ].max, 6 ].min
  end
end
