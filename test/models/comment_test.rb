require "test_helper"

class CommentTest < ActiveSupport::TestCase
  setup do
    @person = trees(:alpha).people.create!(given_names: "Vera", sex: "F")
  end

  test "a comment belongs to a person and the person's tree" do
    comment = @person.comments.create!(user: users(:one), body: "I think she was born in Tver")

    assert_equal trees(:alpha), comment.tree
    assert_includes @person.comments.chronological, comment
  end

  test "a comment needs words and stays short enough to read" do
    assert_not @person.comments.build(user: users(:one), body: " ").valid?
    assert_not @person.comments.build(user: users(:one), body: "x" * 5_001).valid?
  end

  test "comments go with their person, and outlive their author's account" do
    comment = @person.comments.create!(user: users(:one), body: "Hello")
    users(:one).destroy!
    assert_nil comment.reload.user

    assert_difference "Comment.count", -1 do
      @person.destroy!
    end
  end

  test "only the author edits; the author or the owner deletes" do
    owner  = users(:one)
    editor = User.create!(name: "Masha", email_address: "masha@example.com", password: "password")
    TreeMembership.create!(user: editor, tree: trees(:alpha), role: "editor")
    comment = @person.comments.create!(user: editor, body: "Hello")

    assert comment.editable_by?(editor)
    assert_not comment.editable_by?(owner)
    assert comment.deletable_by?(editor)
    assert comment.deletable_by?(owner)
    assert_not @person.comments.create!(user: owner, body: "Hi").deletable_by?(editor)
  end
end
