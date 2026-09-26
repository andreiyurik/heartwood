class People::MapsController < ApplicationController
  include PersonScoped, MapMarkers

  def show
    render json: markers(@person.events)
  end
end
