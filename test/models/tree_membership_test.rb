require "test_helper"

class TreeMembershipTest < ActiveSupport::TestCase
  test "requires a role" do
    m = TreeMembership.new(tree: trees(:alpha), user: users(:one), role: "")
    assert_not m.valid?
    assert m.errors[:role].any?
  end

  test "enforces uniqueness of user per tree" do
    # one_alpha fixture already exists; duplicate should fail
    dup = TreeMembership.new(tree: trees(:alpha), user: users(:one), role: "owner")
    assert_not dup.valid?
    assert dup.errors[:user_id].any?
  end

  test "same user can join different trees" do
    m = TreeMembership.new(tree: trees(:beta), user: users(:one), role: "owner")
    assert m.valid?
  end

  test "different users can join the same tree" do
    m = TreeMembership.new(tree: trees(:alpha), user: users(:two), role: "owner")
    assert m.valid?
  end
end
