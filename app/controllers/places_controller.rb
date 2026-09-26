class PlacesController < ApplicationController
  def search
    @matches = Current.tree.places.search(params[:q]).limit(8)
    render layout: false
  end

  def geocode
    render json: Geocoder.search(params[:q], limit: 6)
  end
end
