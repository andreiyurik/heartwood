require "test_helper"

# docs/features/guides.md "The search route"
class ResearchRouteTest < ActiveSupport::TestCase
  test "with no answers the route is the whole method" do
    assert_equal %w[ask papers place metric_books ww2 repressions names request keep], keys(ResearchRoute.new)
  end

  test "before 1918 the records are the parish books, and a soldier is looked for in the First World War" do
    assert_equal %w[ask papers place metric_books names request keep], keys(ResearchRoute.new(era: "empire"))
    assert_equal %w[ask papers place metric_books ww1 names request keep], keys(ResearchRoute.new(era: "empire", fate: "war"))
    assert_not_includes keys(ResearchRoute.new(era: "empire", fate: "repressed")), "repressions"
  end

  test "between 1918 and 1945 the fate picks the records" do
    assert_equal %w[ask papers place ww2 names request keep], keys(ResearchRoute.new(era: "soviet", fate: "war"))
    assert_equal %w[ask papers place repressions names request keep], keys(ResearchRoute.new(era: "soviet", fate: "repressed"))
    assert_equal %w[ask papers place labour names request keep], keys(ResearchRoute.new(era: "soviet", fate: "labour"))
    assert_equal %w[ask papers place names request keep], keys(ResearchRoute.new(era: "soviet", fate: "unknown"))
  end

  test "after 1945 the place is where the family was registered, not a parish" do
    assert_equal %w[ask papers ww2 names request keep], keys(ResearchRoute.new(era: "later", fate: "war"))
  end

  test "an answer the route does not know is no answer" do
    route = ResearchRoute.new(era: "stone-age", fate: "abducted", region: "atlantis")
    assert_nil route.era
    assert_nil route.fate
    assert_nil route.region
    assert_not route.answered?
    assert ResearchRoute.new(fate: "war").answered?
  end

  test "a step names its guide and the sites to open, with the region's own sites first" do
    books = ResearchRoute.new(era: "empire", region: "belarus").steps.find { it.key == "metric_books" }
    assert_equal "metric-books", books.guide.slug
    assert_equal "belarus", books.sites.first.region
    assert books.sites.all? { it.region.in?([ nil, "belarus" ]) }
    assert_operator books.sites.size, :<=, ResearchRoute::SITES_PER_STEP

    war = ResearchRoute.new(era: "soviet", fate: "war").steps.find { it.key == "ww2" }
    assert_equal %w[pamyat_naroda obd_memorial podvig_naroda], war.sites.map(&:key)
    assert_equal %w[arolsen], ResearchRoute.new(fate: "labour").steps.find { it.key == "labour" }.sites.map(&:key)
    assert_empty ResearchRoute.new.steps.first.sites
  end

  test "every step of every route has its words in both languages" do
    ResearchRoute::ERAS.product(ResearchRoute::FATES).each do |era, fate|
      ResearchRoute.new(era:, fate:).steps.each do |step|
        %i[ru en].each do |locale|
          I18n.with_locale(locale) do
            assert step.title.present? && step.text.present?, "#{step.key} #{locale}"
            assert_no_match(/translation missing/i, step.title + step.text)
          end
        end
      end
    end
  end

  test "the regions offered are the ones the catalog has sites for" do
    assert_equal ResearchSite.all.filter_map(&:region).uniq, ResearchRoute::REGIONS
  end

  private
    def keys(route) = route.steps.map(&:key)
end
