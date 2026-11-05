class People::MapsController < ApplicationController
  include PersonScoped, MapMarkers

  before_action -> { head :not_found }, unless: -> { Maps.tiles? }

  def show
    render json: markers(@person.events)
  end
end
