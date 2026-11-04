require "test_helper"

# Plans and the people cap. See docs/features/monetization.md: free is capped,
# family is unlimited while active, and a lapsed family plan only blocks
# *adding* — it never locks existing data.
class TreePlanTest < ActiveSupport::TestCase
  setup { @tree = trees(:alpha) }

  test "a tree starts on the free plan with a people cap" do
    assert_equal "free", @tree.plan
    assert_equal "free", @tree.effective_plan
    assert_equal Tree::PLANS["free"][:people_limit], @tree.people_limit
    assert_not @tree.family_plan?
  end

  test "an active family plan has no people cap" do
    @tree.update!(plan: "family", plan_expires_at: 1.month.from_now)
    assert @tree.family_plan?
    assert_nil @tree.people_limit
    assert_nil @tree.people_remaining
    assert_not @tree.at_people_limit?
  end

  test "a lapsed family plan falls back to the free cap" do
    @tree.update!(plan: "family", plan_expires_at: 1.day.ago)
    assert_equal "free", @tree.effective_plan
    assert_equal Tree::PLANS["free"][:people_limit], @tree.people_limit
  end

  test "activate_family! extends a running plan from its expiry, a lapsed one from now" do
    @tree.update!(plan: "family", plan_expires_at: 2.months.from_now)
    @tree.activate_family!
    assert_in_delta (2.months.from_now + 1.year).to_i, @tree.plan_expires_at.to_i, 5

    @tree.update!(plan_expires_at: 1.year.ago)
    @tree.activate_family!
    assert_in_delta 1.year.from_now.to_i, @tree.plan_expires_at.to_i, 5
  end

  test "an open-ended family plan stays open-ended when the owner pays" do
    @tree.update!(plan: "family", plan_expires_at: nil)
    @tree.activate_family!
    assert_nil @tree.reload.plan_expires_at
    assert @tree.family_plan?
  end

  test "unknown plans are rejected" do
    @tree.plan = "platinum"
    assert_not @tree.valid?
  end

  test "creating a person past the free cap is blocked, upgrading lifts it" do
    now  = Time.current
    rows = Array.new(@tree.people_limit - @tree.people.count) do
      { tree_id: @tree.id, sex: "U", created_at: now, updated_at: now }
    end
    Person.insert_all(rows)

    over = Person.new(tree: @tree, sex: "U", given_names: "One Too Many")
    assert_not over.valid?
    assert over.errors.of_kind?(:base, :tree_full)

    @tree.activate_family!
    assert Person.new(tree: @tree.reload, sex: "U", given_names: "Fits Now").valid?
  end
end
