require "application_system_test_case"

# The beta's main path, on a phone: a relative gets links in the family chat and does everything without help.
class GrandmotherByLinkTest < ApplicationSystemTestCase
  setup do
    page.driver.browser.execute_cdp("Emulation.setDeviceMetricsOverride", width: 390, height: 844, deviceScaleFactor: 2, mobile: true)
    @tree   = trees(:alpha)
    @vera   = @tree.people.create!(given_names: "Vera", surname: "Ivanova", sex: "F")
    @vera.events.create!(kind: "DEAT", date_raw: "1990")
    @question = @vera.questions.create!(asker: users(:one), body: "What was her mother called?")
  end

  teardown { page.driver.browser.execute_cdp("Emulation.clearDeviceMetricsOverride") }

  test "an invitation, a sign-up, a person, a photo and an answer — on a phone, without instructions" do
    visit join_path(@tree.join_code)
    shot "1-invitation"
    fill_in I18n.t("registrations.name_placeholder"), with: "Grandmother Nina"
    fill_in I18n.t("auth.email_placeholder"), with: "nina@example.com"
    fill_in I18n.t("registrations.password_placeholder"), with: "secret123"
    find("label.auth-consent").click
    click_on I18n.t("joins.submit")
    assert_selector "h1", text: I18n.t("people.title")
    shot "2-people"

    visit new_person_path
    fill_in Person.human_attribute_name(:given_names), with: "Anna Petrovna"
    fill_in Person.human_attribute_name(:surname), with: "Sidorova"
    fill_in Person.human_attribute_name(:born), with: "1899"
    click_on I18n.t("helpers.submit.person.create")
    assert_selector "h1", text: "Anna Petrovna Sidorova"

    attach_file "photos[]", file_fixture("avatar.png"), make_visible: true
    assert_selector "#memories .photo"
    shot "3-profile-with-photo"

    visit question_link_path(@question.token)
    assert_selector "h1", text: "What was her mother called?"
    fill_in I18n.t("answers.placeholder"), with: "Anna Petrovna, née Sidorova"
    shot "4-question"
    click_on I18n.t("answers.submit")
    assert_selector ".thread-entry", text: "Anna Petrovna, née Sidorova"
    assert_equal "Grandmother Nina", @question.answers.sole.user.name
  end

  test "an answer by the question's link alone, with no account at all" do
    visit question_link_path(@question.token)
    shot "5-guest-question"
    fill_in I18n.t("guest_answers.body_placeholder"), with: "Her mother was Anna"
    fill_in I18n.t("guest_answers.name_placeholder"), with: "Aunt Masha"
    click_on I18n.t("guest_answers.submit")
    assert_selector ".answered", text: I18n.t("guest_answers.thanks")
    shot "6-guest-thanks"
    assert_equal [ "Aunt Masha", "Her mother was Anna" ], @question.answers.sole.values_at(:author_name, :body)
  end

  private
    def shot(name)
      return unless (dir = ENV["SHOTS"])
      FileUtils.mkdir_p(dir)
      metrics = page.driver.browser.execute_cdp("Page.getLayoutMetrics")
      size = metrics["cssContentSize"]
      data = page.driver.browser.execute_cdp("Page.captureScreenshot", captureBeyondViewport: true,
        clip: { x: 0, y: 0, width: 390, height: [ size["height"], 3000 ].min, scale: 1 })["data"]
      File.binwrite(File.join(dir, "#{name}.png"), data.unpack1("m0"))
    end
end
