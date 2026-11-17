class ApplicationController < ActionController::Base
  include Authentication
  include TenantScoping
  include TreeAuthorization
  include ActionView::RecordIdentifier
  allow_browser versions: :modern
  stale_when_importmap_changes

  before_action :set_locale

  # What every page shows besides its own records: who is looking, in which language, the header's
  # badge and any flash. A page that calls fresh_when is cached only as long as all of these hold.
  etag { [ Current.session&.id, Current.membership&.role, Current.tree, Current.tree&.duplicate_hints&.pending&.count, I18n.locale, flash.to_hash.presence ] }

  private

  def set_locale
    I18n.locale = available_locale(cookies[:locale]) || browser_locale || I18n.default_locale
  end

  def browser_locale
    request.headers["Accept-Language"].to_s.split(",").lazy
      .map { it[/\A\s*([a-z]{2})/i, 1] }.filter_map { available_locale(it) }.first
  end

  def available_locale(name)
    I18n.available_locales.find { it.to_s == name.to_s.downcase }
  end
end
