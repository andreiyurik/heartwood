class Maps::EventsController < ApplicationController
  include MapMarkers

  before_action -> { head :not_found }, unless: -> { Maps.tiles? }

  def index
    render json: markers(Current.tree.events)
  end
end
