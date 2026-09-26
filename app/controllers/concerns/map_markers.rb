module MapMarkers
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

    # Family events (e.g. marriage) carry no name or link.
    def person_for(event)
      return unless event.eventable.is_a?(Person)
      { name: event.eventable.display_name, url: person_path(event.eventable) }
    end
end
