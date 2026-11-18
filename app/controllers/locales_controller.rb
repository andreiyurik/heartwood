class LocalesController < ApplicationController
  allow_unauthenticated_access

  def update
    locale = params[:locale].to_s.to_sym
    locale = I18n.default_locale unless I18n.available_locales.include?(locale)
    cookies[:locale] = { value: locale, expires: 1.year }
    Current.user&.update!(locale: locale)
    # Secret-link pages send no referrer, so the switcher names its page itself.
    if (page = url_from(params[:return_to]))
      redirect_to page
    else
      redirect_back_or_to root_path, allow_other_host: false
    end
  end
end
