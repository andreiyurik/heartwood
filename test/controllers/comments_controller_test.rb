require "test_helper"

class CommentsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @tree   = trees(:alpha)
    @person = @tree.people.create!(given_names: "Vera", sex: "F")
    @viewer = User.create!(name: "Viewer", email_address: "viewer@example.com", password: "password")
    TreeMembership.create!(user: @viewer, tree: @tree, role: "viewer")
  end

  test "the discussion is the last section of a profile, with a field to add a comment" do
    comment = @person.comments.create!(user: users(:one), body: "The date looks wrong")
    sign_in_as @viewer

    get person_url(@person)
    assert_select "article.person > section:last-of-type#comments" do
      assert_select "##{dom_id(comment)}", text: /The date looks wrong/
      assert_select "turbo-frame#new_comment form[action=?] textarea[name='comment[body]']", person_comments_path(@person)
    end
    assert_select ".profile-nav a[href='#comments']"
  end

  test "a viewer comments, and lands back on the comment" do
    sign_in_as @viewer

    assert_difference "@person.comments.count" do
      post person_comments_url(@person), params: { comment: { body: "She was born in Tver" } }
    end
    comment = @person.comments.last
    assert_equal @viewer, comment.user
    assert_redirected_to person_url(@person, anchor: dom_id(comment))
  end

  test "an empty comment is not posted" do
    sign_in_as @viewer
    assert_no_difference "Comment.count" do
      post person_comments_url(@person), params: { comment: { body: "" } }
    end
    assert_redirected_to person_url(@person, anchor: "comments")
  end

  test "the author edits a comment in place" do
    comment = @person.comments.create!(user: @viewer, body: "Typo")
    sign_in_as @viewer

    get edit_person_comment_url(@person, comment)
    assert_select "turbo-frame##{dom_id(comment, :editor)} form textarea", text: "Typo"

    patch person_comment_url(@person, comment), params: { comment: { body: "Fixed" } }
    assert_equal "Fixed", comment.reload.body
  end

  test "someone else's comment can't be edited, and only the owner may delete it" do
    comment = @person.comments.create!(user: @viewer, body: "Mine")
    sign_in_as users(:one)

    patch person_comment_url(@person, comment), params: { comment: { body: "Changed" } }
    assert_response :forbidden

    assert_difference "Comment.count", -1 do
      delete person_comment_url(@person, comment)
    end
  end

  test "other trees' people take no comments from strangers" do
    sign_in_as users(:two)
    post person_comments_url(@person), params: { comment: { body: "Hi" } }
    assert_response :not_found
  end

  test "a view-only link never shows the discussion" do
    @person.events.create!(kind: "DEAT", date_raw: "1990")
    @person.comments.create!(user: users(:one), body: "Family secret")
    link = @tree.create_share_link!

    get shared_person_url(link.token, @person)
    assert_no_match "Family secret", response.body
  end
end
