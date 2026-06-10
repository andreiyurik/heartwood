class TreesController < ApplicationController
  before_action :find_person

  def show
    result  = params[:mode] == "descendants" ?
                @person.descendant_graph(depth: depth_param) :
                @person.ancestor_graph(depth: depth_param)
    @mode    = result[:mode]
    @graph   = result.except(:persons)
    @persons = result[:persons]
  end

  private

  def find_person
    @person = Person.find(params[:person_id])
  end

  def depth_param
    [[params.fetch(:depth, 4).to_i, 0].max, 6].min
  end
end
