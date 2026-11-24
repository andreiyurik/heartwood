class Guide < Data.define(:slug)
  SLUGS = %w[military metric-books repressions archive-request ai-research].freeze
  SKILL_URL = "https://github.com/DenisSergeevitch/ex-ussr-kinship-research"

  def self.all = SLUGS.map { new(it) }
  def self.find(slug) = (new(slug) if slug.in?(SLUGS)) || raise(ActiveRecord::RecordNotFound)
  def self.indexed? = Rails.configuration.x.guides.indexed

  def to_param = slug
  def title = I18n.t("guides.#{key}.title")
  def description = I18n.t("guides.#{key}.description")
  def sites = ResearchSite.in_guide(slug)

  private
    def key = slug.underscore
end
