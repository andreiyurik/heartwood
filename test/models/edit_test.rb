require "test_helper"

class EditTest < ActiveSupport::TestCase
  setup do
    @tree = trees(:bach)
    @user = users(:bach)
    Current.tree = @tree
    Current.session = @user.sessions.create!
    @sebastian = people(:johann_sebastian)
  end

  test "editing a person records who changed what" do
    @sebastian.update!(given_names: "Johann Sebastian II", nickname: "Thomaskantor")

    edit = @tree.edits.last
    assert edit.edited?
    assert_equal @user, edit.user
    assert_equal @sebastian, edit.subject
    assert_equal @sebastian, edit.person
    assert_equal({ "given_names" => "Johann Sebastian", "nickname" => nil }, edit.particulars["before"])
    assert_equal({ "given_names" => "Johann Sebastian II", "nickname" => "Thomaskantor" }, edit.particulars["after"])
  end

  test "a save that changes nothing records nothing" do
    assert_no_difference -> { Edit.count } do
      @sebastian.update!(given_names: "Johann Sebastian")
      @sebastian.touch
    end
  end

  test "changes made without a signed-in person are not recorded" do
    Current.session = nil
    assert_no_difference -> { Edit.count } do
      @sebastian.update!(nickname: "Thomaskantor")
    end
  end

  test "undoing an edit puts the old values back and marks the edit reverted" do
    @sebastian.update!(given_names: "Typo", nickname: "Thomaskantor")
    edit = @tree.edits.last

    edit.revert(by: @user)

    @sebastian.reload
    assert_equal "Johann Sebastian", @sebastian.given_names
    assert_nil @sebastian.nickname
    assert edit.reload.reverted?
    assert_equal @user, edit.reverted_by
  end

  test "undoing an edit never clobbers a later edit of the same field" do
    @sebastian.update!(given_names: "Typo", nickname: "Thomaskantor")
    edit = @tree.edits.last
    @sebastian.update!(nickname: "Der Alte")

    edit.revert(by: @user)

    @sebastian.reload
    assert_equal "Johann Sebastian", @sebastian.given_names
    assert_equal "Der Alte", @sebastian.nickname
  end

  test "deleting a person records one edit and restoring brings everything back" do
    event_ids  = @sebastian.events.ids
    child_link = family_children(:sebastian_child_of_parents)
    partner_ids = @sebastian.partner_memberships.pluck(:family_id).sort
    citation   = citations(:sebastian_birth_baptism)

    assert_difference -> { Edit.count }, 1 do
      @sebastian.destroy!
    end
    edit = @tree.edits.last
    assert edit.removed?
    assert_equal "Johann Sebastian Bach", edit.particulars["name"]

    edit.revert(by: @user)

    restored = @tree.people.find(@sebastian.id)
    assert_equal "Johann Sebastian", restored.given_names
    assert_equal event_ids.sort, restored.events.ids.sort
    assert_equal citation.page, restored.birth.citations.sole.page
    assert_equal [ child_link.family_id ], restored.child_memberships.pluck(:family_id)
    assert_equal partner_ids, restored.partner_memberships.pluck(:family_id).sort
    assert_includes restored.parents, people(:ambrosius)
    assert edit.reload.reverted?
  end

  test "restoring a person is itself recorded and can be undone again" do
    @sebastian.destroy!
    @tree.edits.last.revert(by: @user)

    restoration = @tree.edits.last
    assert restoration.added?
    assert_equal @sebastian.id, restoration.subject_id
  end

  test "adding an event is recorded against its person and undoing removes it" do
    event = @sebastian.events.create!(kind: "OCCU", value: "Kantor")
    edit = @tree.edits.last
    assert edit.added?
    assert_equal @sebastian, edit.person

    edit.revert(by: @user)

    assert_not Event.exists?(event.id)
  end

  test "a deleted event can be restored with its citations" do
    birth = events(:sebastian_birth)
    birth.destroy!
    edit = @tree.edits.last

    edit.revert(by: @user)

    assert_equal "BIRT", Event.find(birth.id).kind
    assert_equal 1, Event.find(birth.id).citations.count
  end

  test "linking a relative is recorded and undoing unlinks" do
    child = Person.create!(given_names: "Gottfried", sex: "M", tree: @tree)
    @sebastian.add_child(child)
    edit = @tree.edits.where(subject_type: "FamilyChild").last
    assert_equal child, edit.person

    edit.revert(by: @user)

    assert_not_includes @sebastian.children.reload, child
  end

  test "a edit cannot be undone twice" do
    @sebastian.update!(nickname: "Thomaskantor")
    edit = @tree.edits.last
    edit.revert(by: @user)

    assert_not edit.revertable?
    assert_no_difference -> { Edit.count } do
      edit.revert(by: @user)
    end
  end

  test "an edit of a since-deleted record cannot be undone" do
    @sebastian.update!(nickname: "Thomaskantor")
    edit = @tree.edits.last
    @sebastian.destroy!

    assert_not edit.reload.revertable?
  end
end
