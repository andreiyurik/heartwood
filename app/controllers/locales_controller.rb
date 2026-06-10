class LocalesController < ApplicationController
  allow_unauthenticated_access

  def update
    locale = params[:locale].to_sym
    locale = I18n.default_locale unless I18n.available_locales.include?(locale)
    cookies[:locale] = { value: locale, expires: 1.year }
    redirect_back_or_to root_path, allow_other_host: false
  end
end
