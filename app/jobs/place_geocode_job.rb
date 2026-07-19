# Background fallback for places created without picked coordinates — typed text
# or a GEDCOM import. Resolves the name via Nominatim so it can earn a map pin. A
# place we can't resolve simply stays pin-less — never an error. See Geocoder and
# place.md.
class PlaceGeocodeJob < ApplicationJob
  queue_as :default

  def perform(place)
    return if place.geocoded?

    match = Geocoder.search(place.gedcom_raw.presence || place.name, limit: 1).first
    return unless match

    place.update!(latitude: match[:lat], longitude: match[:lng])
  end
end
