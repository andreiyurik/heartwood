class ResearchRoute
  ERAS = %w[empire soviet later].freeze
  FATES = %w[war repressed labour unknown].freeze
  REGIONS = ResearchSite.all.filter_map(&:region).uniq.freeze
  SITES_PER_STEP = 4

  Step = Data.define(:key, :art, :variant, :guide, :sites) do
    def title = I18n.t("research_route.steps.#{key}.title")
    def text = I18n.t("research_route.steps.#{key}.#{variant}")
  end

  attr_reader :era, :fate, :region

  def initialize(era: nil, fate: nil, region: nil)
    @era, @fate, @region = era.presence_in(ERAS), fate.presence_in(FATES), region.presence_in(REGIONS)
  end

  def answers = { era:, fate:, region: }.compact
  def answered? = answers.any?

  def steps
    [ step("ask"), step("papers"), (step("place") unless era == "later"), *records, step("names"), request, step("keep") ].compact
  end

  private
    def records
      [
        (step("metric_books", art: "records", guide: "metric-books") if era.in?([ nil, "empire" ])),
        (step("ww1", art: "records", guide: "military", sites: %w[gwar]) if era == "empire" && fate == "war"),
        (step("ww2", art: "records", guide: "military", sites: %w[pamyat_naroda obd_memorial podvig_naroda]) if soviet_fate?("war")),
        (step("repressions", art: "records", guide: "repressions") if soviet_fate?("repressed")),
        (step("labour", art: "records", guide: "military", sites: %w[arolsen]) if fate == "labour" && era != "empire")
      ]
    end

    # An unanswered fate is every fate: the route shows what that time could have left.
    def soviet_fate?(name) = era != "empire" && fate.in?([ nil, name ])

    def request
      if era.in?(%w[soviet later])
        step("request", variant: "zags", guide: "archive-request", sites: %w[gosuslugi])
      else
        step("request", variant: "archive", guide: "archive-request", sites: %w[archive_guides])
      end
    end

    def step(key, art: key, variant: "text", guide: nil, sites: nil)
      guide &&= Guide.find(guide)
      Step.new(key:, art:, variant:, guide:, sites: sites ? sites.map { ResearchSite.find(it) } : sites_of(guide))
    end

    def sites_of(guide)
      return [] unless guide
      local, general = guide.sites.select { it.region.in?([ nil, region ]) }.partition(&:region)
      (local + general).first(SITES_PER_STEP)
    end
end
