class PlaceGeocodeJob < ApplicationJob
  queue_as :default

  def perform(place)
    return if place.geocoded?

    match = Geocoder.search(place.gedcom_raw.presence || place.name, limit: 1).first
    return unless match

    place.update!(latitude: match[:lat], longitude: match[:lng])
  end
end
