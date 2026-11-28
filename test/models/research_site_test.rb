require "test_helper"

# docs/features/guides.md "The site catalog"
class ResearchSiteTest < ActiveSupport::TestCase
  setup { @tree = trees(:alpha) }

  test "every site has an https-or-http link, a known tier and a name and description in every language" do
    assert ResearchSite.all.many?
    ResearchSite.all.each do |site|
      assert_match %r{\Ahttps?://}, site.url, site.key
      assert_includes ResearchSite::TIERS, site.tier, site.key
      I18n.available_locales.each do |locale|
        assert I18n.exists?("research_sites.#{site.key}.name", locale), "#{site.key} name in #{locale}"
        assert I18n.exists?("research_sites.#{site.key}.about", locale), "#{site.key} about in #{locale}"
      end
    end
  end

  test "every site belongs to a guide that exists, and every guide lists sites" do
    ResearchSite.all.each { assert_includes Guide::SLUGS, it.guide, it.key }
    Guide::SLUGS.excluding("start", "ai-research").each do |slug|
      assert ResearchSite.in_guide(slug).any?, slug
    end
  end

  test "a person who lived through the war is pointed to the war's databases" do
    person = @tree.people.create!(given_names: "Иван Петрович", surname: "Сидоров", sex: "M", born: "1912", died: "1985")
    keys = ResearchSite.for(person).map(&:key)

    assert_includes keys, "pamyat_naroda"
    assert_includes keys, "metric_books_familysearch"
    assert_not_includes keys, "gwar"
  end

  test "a child during the war is not sent to the soldiers' databases" do
    person = @tree.people.create!(given_names: "Анна", sex: "F", born: "1938", died: "2001")
    assert_not_includes ResearchSite.for(person).map(&:key), "pamyat_naroda"
  end

  test "an old man in the war years is not sent to the soldiers' databases either" do
    person = @tree.people.create!(given_names: "Александр", sex: "M", born: "1833", died: "1914")
    assert_not_includes ResearchSite.for(person).map(&:key), "gwar"
  end

  test "a known death year alone is enough to guess the lifetime" do
    person = @tree.people.create!(given_names: "Пётр", sex: "M", died: "1916")
    assert_includes ResearchSite.for(person).map(&:key), "gwar"
  end

  test "living people and people with no dates get no suggestions" do
    assert_empty ResearchSite.for(@tree.people.create!(given_names: "Мария", sex: "F", born: "1990"))
    assert_empty ResearchSite.for(@tree.people.create!(given_names: "Мария", sex: "F"))
  end

  test "a site with a search template opens the search with the person's name filled in" do
    person = @tree.people.create!(given_names: "Иван Петрович", surname: "Сидоров", sex: "M", born: "1912", died: "1985")
    url = ResearchSite.find("pamyat_naroda").search_url_for(person)

    assert_includes url, "last_name=#{CGI.escape("Сидоров")}"
    assert_includes url, "first_name=#{CGI.escape("Иван")}"
    assert_includes url, "middle_name=#{CGI.escape("Петрович")}"
    assert_nil ResearchSite.find("obd_memorial").search_url_for(person)
  end
end
