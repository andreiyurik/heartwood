# Pin npm packages by running ./bin/importmap

pin "application"
pin "@hotwired/turbo-rails", to: "turbo.min.js"
pin "@hotwired/stimulus", to: "stimulus.min.js"
pin "@hotwired/stimulus-loading", to: "stimulus-loading.js"
pin_all_from "app/javascript/controllers", under: "controllers"

# Shared Leaflet helpers used by the map and place controllers
pin "maps"

# Lexxy rich text editor (ships its own bundled JS on the asset load path)
pin "lexxy"

# Leaflet — map rendering for the place views (MIT, no API key). Self-hosted:
# vendored ESM in vendor/javascript, CSS in app/assets, marker images in public/leaflet.
pin "leaflet", to: "leaflet.js"
