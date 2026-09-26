class Maps::EventsController < ApplicationController
  include MapMarkers

  def index
    render json: markers(Current.tree.events)
  end
end
