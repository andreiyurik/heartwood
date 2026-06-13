# Place autocomplete for the event form: matching places in the current tree,
# rendered as a suggestion list the place Stimulus controller drops into the form.
class PlacesController < ApplicationController
  def search
    @matches = Current.tree.places.search(params[:q]).limit(8)
    render layout: false # a bare fragment for the autocomplete dropdown, never a full page
  end

  # On-demand geocoding for the place picker: candidate locations for a typed
  # place name, so the user can confirm one on a map.
  def geocode
    render json: Geocoder.search(params[:q], limit: 6)
  end
end
