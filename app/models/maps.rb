module Maps
  # "off" rather than empty: Kamal passes an empty value as a bare --env KEY, which falls back to OSM.
  OFF = [ "", "off" ].freeze

  def self.config = Rails.configuration.x.maps
  def self.tiles? = !config.tiles_url.to_s.in?(OFF)
  def self.geocoder? = !config.geocoder_url.to_s.in?(OFF)

  def self.tiles_host = host(config.tiles_url)
  def self.geocoder_host = host(config.geocoder_url)

  # Tile URLs are Leaflet templates ("{s}.tile…"), which URI cannot parse.
  def self.host(url) = url.to_s[%r{\A\w+://([^/]+)}, 1]&.delete_prefix("{s}.")
  private_class_method :host
end
