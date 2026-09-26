require "net/http"

# Called once per explicit user action, never per keystroke: Nominatim's usage policy.
class Geocoder
  ENDPOINT   = "https://nominatim.openstreetmap.org/search".freeze
  USER_AGENT = "Heartwood/0.1 (open-source family tree)".freeze

  def self.search(query, limit: 5)
    new.search(query, limit:)
  end

  def search(query, limit: 5)
    query = query.to_s.strip
    return [] if query.blank?

    Array(request(query, limit)).map do |result|
      {
        name:         result["display_name"].to_s.split(",").first&.strip,
        display_name: result["display_name"],
        lat:          result["lat"].to_f,
        lng:          result["lon"].to_f
      }
    end
  rescue StandardError => e
    Rails.logger.info("Geocoder failed for #{query.inspect}: #{e.message}")
    []
  end

  private

  def request(query, limit)
    uri = URI(ENDPOINT)
    uri.query = URI.encode_www_form(q: query, format: "json", limit: limit)

    get = Net::HTTP::Get.new(uri)
    get["User-Agent"] = USER_AGENT

    # Short timeouts: a slow Nominatim must not pin a web thread.
    response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true,
      open_timeout: 3, read_timeout: 3) { |http| http.request(get) }
    return unless response.is_a?(Net::HTTPSuccess)

    JSON.parse(response.body)
  end
end
