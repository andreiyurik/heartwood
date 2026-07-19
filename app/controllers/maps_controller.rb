# Map data and pages for the place views. The JSON actions feed the Leaflet
# Stimulus controller; events without geocoded places are simply left off the
# map (graceful degradation). See place.md and the family map feature.
class MapsController < ApplicationController
  # Whole-tree map page.
  def show
  end

  # Markers for every geolocated event in the tree.
  def events
    render json: markers(Current.tree.events)
  end

  # Markers for one person's geolocated events (the profile Map tab).
  def person
    person = Current.tree.people.visible_to(Current.user).find(params[:id])
    render json: markers(person.events)
  end

  private

  def markers(events)
    events.includes(:place, :eventable).filter_map do |event|
      place = event.place
      next unless place&.geocoded?

      {
        lat:    place.latitude.to_f,
        lng:    place.longitude.to_f,
        kind:   event.kind_label,
        date:   event.date_raw,
        place:  place.name,
        person: person_for(event)
      }
    end
  end

  # Only Person events carry a name/link; Family events (e.g. marriage) don't.
  def person_for(event)
    return unless event.eventable.is_a?(Person)
    { name: event.eventable.display_name, url: person_path(event.eventable) }
  end
end
