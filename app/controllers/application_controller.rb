class ApplicationController < ActionController::Base
  include Authentication
  include TenantScoping
  include TreeAuthorization
  include ActionView::RecordIdentifier
  allow_browser versions: :modern
  stale_when_importmap_changes

  before_action :set_locale

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
