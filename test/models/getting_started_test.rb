require "test_helper"

# docs/features/getting-started.md
class GettingStartedTest < ActiveSupport::TestCase
  setup do
    @tree = Tree.create!(name: "Ивановы")
    @owner = User.create!(name: "Аня", email_address: "anya@example.com", password: "password")
    @tree.tree_memberships.create!(user: @owner, role: "owner")
  end

  test "each step ticks itself from what the tree holds" do
    assert_equal [ false, false, false ], steps.map(&:done?)

    me = person("Аня")
    assert_equal [ true, false, false ], steps.map(&:done?)

    dad = me.add_parent(person("Иван"))
    assert_not GettingStarted.new(@tree).steps.second.done?
    dad.add_parent(person("Пётр"))
    assert_equal [ true, true, false ], steps.map(&:done?)

    me.questions.create!(asker: @owner, body: "Где родилась бабушка?")
    assert_equal [ true, true, true ], steps.map(&:done?)
    assert GettingStarted.new(@tree).done?
  end

  test "a relative who joined counts as asking the family" do
    person("Аня")
    @tree.tree_memberships.create!(user: users(:two), role: "viewer")
    assert steps.third.done?
  end

  test "parents are added to the earliest person who has none yet: first you, then your father" do
    me = person("Аня")
    assert_equal me, GettingStarted.new(@tree).parents_for

    dad = me.add_parent(person("Иван"))
    assert_equal dad, GettingStarted.new(@tree).parents_for
  end

  test "the family is asked about the latest person whose birth nobody has written down" do
    me = person("Аня").tap { it.events.create!(kind: "BIRT", date_raw: "1990") }
    grandma = person("Вера")
    person("Пётр").events.create!(kind: "BIRT", date_raw: "1920")

    assert_equal grandma, GettingStarted.new(@tree).ask_about
    grandma.events.create!(kind: "BIRT", date_raw: "1925")
    assert_equal @tree.people.order(:id).last, GettingStarted.new(@tree).ask_about
    assert me
  end

  private
    def steps = GettingStarted.new(@tree).steps

    def person(given_names) = @tree.people.create!(given_names: given_names)
end
