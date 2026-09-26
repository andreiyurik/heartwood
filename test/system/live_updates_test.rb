require "application_system_test_case"

class LiveUpdatesTest < ApplicationSystemTestCase
  include ActiveJob::TestHelper

  setup do
    @previous_adapter = ActiveJob::Base.queue_adapter
    ActiveJob::Base.queue_adapter = :inline
    ActionCable.server.config.cable = { "adapter" => "async" }
    ActionCable.server.restart
    @person = people(:johann_sebastian)
    sign_in_as users(:bach)
  end

  teardown do
    ActiveJob::Base.queue_adapter = @previous_adapter
    ActionCable.server.config.cable = { "adapter" => "test" }
    ActionCable.server.restart
  end

  test "a relative sees an event someone else adds without reloading" do
    visit person_path(@person)
    assert_selector ".event-list", text: "Death"
    assert_no_text "Baptism"

    @person.events.create!(kind: "BAPM", date_raw: "23 MAR 1685")

    assert_selector ".event-list", text: "Baptism", wait: 10
  end

  test "a new person appears on an open people list" do
    visit people_path
    assert_no_text "Johann Nikolaus"

    Person.create!(given_names: "Johann Nikolaus", surname: "Bach", sex: "M", tree: trees(:bach))

    assert_text "Johann Nikolaus", wait: 10
  end

  test "an open tree redraws when a parent is added" do
    visit person_tree_path(people(:wilhelm_friedemann), depth: 1)
    assert_selector ".tree-node", count: 3
    extra = Person.create!(given_names: "Ghost", surname: "Parent", sex: "M", tree: trees(:bach))
    families(:first_marriage).partners << extra

    assert_selector ".tree-node", count: 4, wait: 10
  end

  test "a refresh does not close or wipe a form someone is filling in" do
    visit person_path(@person)
    click_on I18n.t("events.add")
    fill_in "event_date_raw", with: "typed but not saved"

    @person.events.create!(kind: "BAPM", date_raw: "23 MAR 1685")
    assert_selector ".event-list", text: "Baptism", wait: 10

    assert_field "event_date_raw", with: "typed but not saved"
  end

  test "saving an inline form updates the list and closes the form" do
    visit person_path(@person)
    click_on I18n.t("events.add_residence")
    fill_in "event_date_raw", with: "1723"
    find("form.form--inline input[type=submit]").click

    assert_selector ".event-list", text: "1723", wait: 10
    assert_no_field "event_date_raw"
    assert_link I18n.t("events.add_residence")
  end

  test "deleting an event removes it from the list at once" do
    visit person_path(@person)
    assert_selector ".event-row", text: "Death"

    accept_confirm { within(".event-row", text: "Death") { click_on I18n.t("events.remove") } }

    assert_no_selector ".event-row", text: "Death", wait: 10
  end

  test "adding a relative from the profile shows them in the family box and closes the form" do
    visit person_path(people(:wilhelm_friedemann))
    within("#add_child") { click_on I18n.t("family.add", relation: I18n.t("family.relation_singular.child")) }
    within("#add_child") do
      fill_in "person_given_names", with: "Friedemann Junior"
      find("input[type=submit]").click
    end

    assert_selector "#family", text: "Friedemann Junior", wait: 10
    assert_no_selector "#add_child input[type=submit]"
  end

  test "citing an event refreshes its sourced badge and closes the form" do
    visit person_path(@person)
    within(".event-row", text: "Death") { click_on I18n.t("citations.add") }
    fill_in "source_title", with: "Leipzig burial register"
    find("form.form--inline input[type=submit]").click

    within(".event-row", text: "Death") { assert_selector ".sourced-badge", wait: 10 }
    assert_no_field "source_title"
  end
end
