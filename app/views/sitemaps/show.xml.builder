xml.instruct!
xml.urlset xmlns: "http://www.sitemaps.org/schemas/sitemap/0.9" do
  if @guides.any?
    xml.url { xml.loc landing_url }
    I18n.available_locales.each do |locale|
      xml.url { xml.loc guides_url(locale: locale) }
      @guides.each { |guide| xml.url { xml.loc guide_url(guide, locale: locale) } }
    end
  end
end
