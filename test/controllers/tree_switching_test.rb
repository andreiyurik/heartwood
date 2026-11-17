require "test_helper"

class TreeSwitchingTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    TreeMembership.create!(user: @user, tree: trees(:beta), role: "editor")
    @elsewhere = trees(:beta).people.create!(given_names: "Else")
    sign_in_as @user
  end

  test "a link from a letter to a person in another of your trees switches to that tree" do
    get person_url(@elsewhere)
    assert_redirected_to person_url(@elsewhere)
    follow_redirect!
    assert_response :success
    assert_equal trees(:beta), Session.find(Current.session.id).current_tree
  end

  test "the same for a question" do
    question = @elsewhere.questions.create!(asker: users(:two), body: "Who?")
    get question_url(question)
    follow_redirect!
    assert_response :success
  end

  test "a tree you don't belong to stays out of reach" do
    stranger = trees(:bach).people.create!(given_names: "Stranger")
    get person_url(stranger)
    assert_response :not_found
  end
end
