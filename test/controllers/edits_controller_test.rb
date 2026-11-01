require "test_helper"

class EditsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @tree = trees(:bach)
    sign_in_as users(:bach)
    Current.tree = @tree
    @sebastian = people(:johann_sebastian)
    @sebastian.update!(nickname: "Thomaskantor")
    @edit = @tree.edits.last
  end

  test "requires authentication" do
    sign_out
    get edits_url
    assert_redirected_to new_session_url
  end

  test "lists the tree's history with an undo button" do
    get edits_url
    assert_response :success
    assert_select "#edits .edit-row", 1 do
      assert_select "a[href=?]", person_path(@sebastian), text: "Johann Sebastian Bach"
      assert_select "form[action=?]", edit_reversion_path(@edit)
    end
  end

  test "names a person as they are now, not as they were then" do
    @sebastian.update!(given_names: "J. S.")
    get edits_url
    assert_select ".edit-row a[href=?]", person_path(@sebastian), text: "J. S. Bach", count: 2
  end

  test "shows nothing from another tree" do
    Current.set(session: users(:two).sessions.create!, tree: trees(:beta)) { Person.create!(given_names: "Stranger", sex: "U") }
    get edits_url
    assert_select ".edit-row", 1
    assert_no_match "Stranger", response.body
  end

  test "undo reverts the edit" do
    post edit_reversion_url(@edit)
    assert_redirected_to edits_url
    assert_nil @sebastian.reload.nickname
    assert @edit.reload.reverted?
  end

  test "a reverted edit shows who undid it instead of a button" do
    post edit_reversion_url(@edit)
    get edits_url
    assert_select "form[action=?]", edit_reversion_path(@edit), count: 0
    assert_select ".edit-row", text: /Johann Bach/
  end

  test "cannot undo an edit from another tree" do
    other = Current.set(session: users(:two).sessions.create!, tree: trees(:beta)) { Person.create!(given_names: "X", sex: "U") }
    post edit_reversion_url(other.edits.last)
    assert_response :not_found
  end

  test "a viewer sees history but cannot undo" do
    viewer = User.create!(name: "Viewer", email_address: "viewer@example.com", password: "password")
    TreeMembership.create!(user: viewer, tree: @tree, role: "viewer")
    sign_out
    sign_in_as viewer

    get edits_url
    assert_select ".edit-row", 1
    assert_select "form[action=?]", edit_reversion_path(@edit), count: 0

    post edit_reversion_url(@edit)
    assert_response :forbidden
    assert_equal "Thomaskantor", @sebastian.reload.nickname
  end

  test "deleting a person offers undo right in the flash" do
    delete person_url(@sebastian)
    follow_redirect!
    assert_select ".flash form[action=?]", edit_reversion_path(@tree.edits.removed.last)
  end
end
