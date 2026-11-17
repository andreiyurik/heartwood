require "test_helper"

class TreeSwitchingTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    TreeMembership.create!(user: @user, tree: trees(:beta), role: "editor")
    @elsewhere = trees(:beta).people.create!(given_names: "Else")
    sign_in_as @user
  end

  test "a letter's link into another of your trees switches to that tree and drops the marker" do
    get person_url(@elsewhere, tree: trees(:beta).id)
    assert_redirected_to person_url(@elsewhere)
    follow_redirect!
    assert_response :success
    assert_equal trees(:beta), Session.find(Current.session.id).current_tree
  end

  test "the same for a question" do
    question = @elsewhere.questions.create!(asker: users(:two), body: "Who?")
    get question_url(question, tree: trees(:beta).id)
    follow_redirect!
    assert_response :success
  end

  test "a page refresh in a background tab never moves the session to another tree" do
    get person_url(@elsewhere)
    assert_response :not_found
    assert_not_equal trees(:beta), Session.find(Current.session.id).current_tree
  end

  test "a tree you don't belong to stays out of reach" do
    stranger = trees(:bach).people.create!(given_names: "Stranger")
    get person_url(stranger, tree: trees(:bach).id)
    follow_redirect!
    assert_response :not_found
  end

  test "letters mark their links with the tree" do
    Current.session = users(:two).sessions.create!
    trees(:alpha).people.create!(given_names: "Vera")
    Current.reset
    body = DigestMailer.weekly(tree_memberships(:one_alpha)).html_part.body.to_s
    assert_match "tree=#{trees(:alpha).id}", body
  end
end
