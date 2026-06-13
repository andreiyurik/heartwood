# Pin npm packages by running ./bin/importmap

pin "application"
pin "@hotwired/turbo-rails", to: "turbo.min.js"
pin "@hotwired/stimulus", to: "stimulus.min.js"
pin "@hotwired/stimulus-loading", to: "stimulus-loading.js"
pin_all_from "app/javascript/controllers", under: "controllers"

# Lexxy rich text editor (ships its own bundled JS on the asset load path)
pin "lexxy"

# Leaflet — map rendering for the place views (MIT, no API key)
pin "leaflet", to: "https://unpkg.com/leaflet@1.9.4/dist/leaflet-src.esm.js"
