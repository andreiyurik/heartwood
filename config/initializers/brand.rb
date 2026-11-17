# Locale strings say %{app} wherever the service names itself; this fills it in for every lookup.
module BrandInterpolation
  def translate(locale, key, options = {})
    super(locale, key, { app: Rails.configuration.x.brand.name }.merge(options))
  end
end

I18n::Backend::Simple.prepend BrandInterpolation
