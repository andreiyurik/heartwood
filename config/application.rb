require_relative "boot"

require "rails/all"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Heartwood
  # AGPL §13: users of a modified hosted copy must be offered its source.
  SOURCE_CODE_URL = ENV.fetch("SOURCE_CODE_URL", "https://github.com/andreiyurik/heartwood")

  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 8.1

    # Please, add to the `ignore` list any other `lib` subdirectories that do
    # not contain `.rb` files, or that should not be reloaded or eager loaded.
    # Common ones are `templates`, `generators`, or `middleware`, for example.
    config.autoload_lib(ignore: %w[assets tasks])

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    config.i18n.available_locales = %i[en ru]
    config.i18n.default_locale   = :en

    config.x.brand.name = ENV.fetch("BRAND_NAME", "Heartwood")
    config.x.operator = config_for(:operator)
    config.x.maps = config_for(:maps)
    config.x.guides.indexed = ENV["GUIDES_INDEX"] == "on"
    config.x.landing.demo_url = ENV["DEMO_URL"].presence
    config.x.landing.demo_owner = ENV["DEMO_OWNER"].presence

    config.x.backups.directory = Rails.root.join("storage/backups")
    config.x.backups.offsite   = ENV["BACKUP_BUCKET"].present?

    config.action_mailer.default_options = { from: "#{config.x.brand.name} <no-reply@localhost>" }

    # config.time_zone = "Central Time (US & Canada)"
    # config.eager_load_paths << Rails.root.join("extras")
  end
end
