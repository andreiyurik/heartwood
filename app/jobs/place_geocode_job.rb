require "net/http"

# Best-effort geocoding via OpenStreetMap's Nominatim — free, no API key. A place
# we can't resolve simply stays pin-less; we never raise into the queue or block
# import over a flaky third party. See place.md.
class PlaceGeocodeJob < ApplicationJob
  queue_as :default

  ENDPOINT   = "https://nominatim.openstreetmap.org/search".freeze
  USER_AGENT = "Heartwood/0.1 (open-source family tree)".freeze

  def perform(place)
    return if place.geocoded?

    match = lookup(place.gedcom_raw.presence || place.name)
    return unless match

    place.update!(latitude: match["lat"], longitude: match["lon"])
  rescue StandardError => e
    Rails.logger.info("PlaceGeocodeJob skipped place #{place.id}: #{e.message}")
  end

  private

  def lookup(query)
    uri = URI(ENDPOINT)
    uri.query = URI.encode_www_form(q: query, format: "json", limit: 1)

    request = Net::HTTP::Get.new(uri)
    request["User-Agent"] = USER_AGENT

    response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true,
      open_timeout: 5, read_timeout: 5) { |http| http.request(request) }
    return unless response.is_a?(Net::HTTPSuccess)

    JSON.parse(response.body).first
  end
end
