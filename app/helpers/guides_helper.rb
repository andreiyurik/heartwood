module GuidesHelper
  def guide_json_ld(guide)
    [
      { "@context": "https://schema.org", "@type": "Article", headline: guide.title, description: guide.description,
        inLanguage: I18n.locale, url: guide_url(guide, locale: I18n.locale), isBasedOn: Guide::SKILL_URL,
        publisher: { "@type": "Organization", name: brand_name } },
      { "@context": "https://schema.org", "@type": "BreadcrumbList", itemListElement: [
        { "@type": "ListItem", position: 1, name: t("guides.index.title"), item: guides_url(locale: I18n.locale) },
        { "@type": "ListItem", position: 2, name: guide.title, item: guide_url(guide, locale: I18n.locale) }
      ] }
    ]
  end

  def guides_json_ld(guides)
    { "@context": "https://schema.org", "@type": "CollectionPage", name: t("guides.index.title"), inLanguage: I18n.locale,
      hasPart: guides.map { { "@type": "Article", headline: it.title, url: guide_url(it, locale: I18n.locale) } } }
  end
end
