class ResearchSite < Data.define(:key, :url, :tier, :guide, :years, :adult, :search, :region)
  TIERS = %w[official project community].freeze
  ADULT_AGE = 16
  OLDEST_SOLDIER = 50
  # A person with only one known year lived roughly this long.
  LIFETIME = 80

  def self.all
    @all ||= YAML.load_file(Rails.root.join("config/research_sites.yml"), permitted_classes: [ Date ]).map do |key, site|
      new(key:, url: site["url"], tier: site["tier"], guide: site["guide"], years: site["years"]&.then { Range.new(*it) },
          adult: site["adult"].present?, search: site["search"], region: site["region"])
    end.freeze
  end

  def self.find(key) = all.find { it.key == key } || raise(ActiveRecord::RecordNotFound)
  def self.in_guide(slug) = all.select { it.guide == slug }

  def self.for(person)
    return [] if person.living?
    born, died = person.birth&.date_start&.year, person.death&.date_start&.year
    return [] unless born || died
    lifetime = (born || died - LIFETIME)..(died || born + LIFETIME)
    all.select { it.covers?(lifetime, born_known: born.present?) }
  end

  def name = I18n.t("research_sites.#{key}.name")
  def about = I18n.t("research_sites.#{key}.about")
  def region_name = (I18n.t("research_sites.regions.#{region}") if region)

  def covers?(lifetime, born_known: true)
    return false unless years
    return false if adult && born_known && lifetime.begin + OLDEST_SOLDIER < years.begin
    from = adult ? lifetime.begin + ADULT_AGE : lifetime.begin
    from <= [ years.end, lifetime.end ].min && lifetime.end >= years.begin
  end

  def search_url_for(person)
    return unless search
    first_name, patronymic = person.given_names.to_s.split(" ", 2)
    format(search, **{ surname: person.surname, first_name:, patronymic: }.transform_values { CGI.escape(it.to_s) })
  end
end
