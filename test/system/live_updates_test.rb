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
end
