# Place autocomplete for the event form: matching places in the current tree,
# rendered as a suggestion list the place Stimulus controller drops into the form.
class PlacesController < ApplicationController
  def search
    @matches = Current.tree.places.search(params[:q]).limit(8)
  end
end
