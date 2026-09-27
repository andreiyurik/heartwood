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

  # --- roles (owner / editor / viewer) — see [[collaboration]] ---

  test "rejects a role outside owner/editor/viewer" do
    m = TreeMembership.new(tree: trees(:beta), user: users(:one), role: "admin")
    assert_not m.valid?
    assert m.errors[:role].any?
  end

  test "owner?/editor?/viewer? reflect the role" do
    owner = tree_memberships(:one_alpha)
    assert owner.owner?
    assert_not owner.editor?
    assert_not owner.viewer?
  end

  test "can_edit? is true for owner and editor, false for viewer" do
    assert TreeMembership.new(role: "owner").can_edit?
    assert TreeMembership.new(role: "editor").can_edit?
    assert_not TreeMembership.new(role: "viewer").can_edit?
  end

  test "defaults to the least privileged role" do
    membership = TreeMembership.new
    assert membership.viewer?
  end

  test "roles come with predicates and scopes" do
    membership = tree_memberships(:one_alpha)
    assert membership.owner?
    assert_not membership.viewer?
    assert_includes TreeMembership.owner, membership
    assert_not_includes TreeMembership.viewer, membership

    membership.viewer!
    assert membership.viewer?
    assert_not membership.can_edit?
  end
end
