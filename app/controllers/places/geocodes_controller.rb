class Places::GeocodesController < ApplicationController
  def show
    render json: Geocoder.search(params[:q], limit: 6)
  end
end
