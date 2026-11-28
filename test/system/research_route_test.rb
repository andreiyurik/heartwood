require "application_system_test_case"

# docs/features/guides.md "The search route"
class ResearchRouteGuideTest < ApplicationSystemTestCase
  test "answering makes the route the reader's own, in place, under an address that can be sent on" do
    visit guide_path("start", locale: "ru")
    assert_selector ".route-step", count: ResearchRoute.new.steps.size

    find("label.choice", text: I18n.t("research_route.eras.soviet", locale: :ru)).click
    find("label.choice", text: I18n.t("research_route.fates.war", locale: :ru)).click

    assert_selector ".route-step", count: ResearchRoute.new(era: "soviet", fate: "war").steps.size
    assert_selector ".route-step h2", text: I18n.t("research_route.steps.ww2.title", locale: :ru)
    assert_current_path guide_path("start", locale: "ru", era: "soviet", fate: "war", region: "")
  end

  test "a finished step stays ticked in this browser" do
    visit guide_path("start", locale: "ru")
    page.execute_script("localStorage.clear()")
    visit guide_path("start", locale: "ru")

    first(".route-step__done input").check
    assert_selector "[data-checklist-target=count]", text: "1 из #{ResearchRoute.new.steps.size}"

    visit guide_path("start", locale: "ru", era: "empire")
    assert first(".route-step__done input").checked?
    assert_selector "[data-checklist-target=count]", text: "1 из #{ResearchRoute.new(era: "empire").steps.size}"
  end

  test "the first step's button leaves the route for the page it names" do
    visit guide_path("start", locale: "ru")
    click_on I18n.t("research_route.ask_family", locale: :ru)

    assert_current_path new_registration_path
    assert_no_text "Content missing"
  end
end
