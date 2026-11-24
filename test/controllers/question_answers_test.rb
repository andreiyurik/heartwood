require "test_helper"

class QuestionAnswersTest < ActionDispatch::IntegrationTest
  setup do
    @owner = users(:one)
    person = trees(:alpha).people.create!(given_names: "Vera", surname: "Ivanova", sex: "F")
    @question = person.questions.create!(asker: @owner, body: "What was her mother called?")
    sign_in_as @owner
  end

  test "a member answers in the thread" do
    assert_difference "@question.answers.count" do
      post question_answers_url(@question), params: { answer: { body: "Anna" } }
    end
    assert_redirected_to question_url(@question, anchor: "answer_#{@question.answers.last.id}")
  end

  test "a blank answer is refused kindly" do
    assert_no_difference "Answer.count" do
      post question_answers_url(@question), params: { answer: { body: " " } }
    end
    assert_redirected_to question_url(@question)
    assert_equal I18n.t("answers.flash.blank"), flash[:alert]
  end

  test "a closed question takes no more answers" do
    @question.close(by: @owner)
    assert_no_difference "Answer.count" do
      post question_answers_url(@question), params: { answer: { body: "Late" } }
    end
    assert_redirected_to question_url(@question)
  end

  test "the owner removes an answer" do
    answer = @question.answers.create!(body: "Wrong", author_name: "Someone")
    assert_difference "Answer.count", -1 do
      delete question_answer_url(@question, answer)
    end
    assert_redirected_to question_url(@question)
  end

  test "a viewer cannot remove someone else's answer" do
    answer = @question.answers.create!(body: "Keep", author_name: "Someone")
    viewer = User.create!(name: "View Er", email_address: "v@example.com", password: "password")
    TreeMembership.create!(user: viewer, tree: trees(:alpha), role: "viewer")
    delete session_url
    post session_url, params: { email_address: viewer.email_address, password: "password" }
    assert_no_difference "Answer.count" do
      delete question_answer_url(@question, answer)
    end
    assert_response :forbidden
  end
end
