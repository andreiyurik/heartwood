require "test_helper"

class QuestionsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @tree   = trees(:alpha)
    @owner  = users(:one)
    @person = @tree.people.create!(given_names: "Vera", surname: "Ivanova", sex: "F")
    @person.events.create!(kind: "DEAT", date_raw: "1990")
    sign_in_as @owner
  end

  test "an editor asks about a person in place on the profile and lands on the question to send it" do
    get person_url(@person)
    assert_select "a[href=?][data-turbo-frame=new_question]", new_person_question_path(@person)

    get new_person_question_url(@person)
    assert_select "turbo-frame#new_question form[action=?] textarea[name='question[body]']", person_questions_path(@person)

    assert_difference "Question.count" do
      post person_questions_url(@person), params: { question: { body: "What was her mother called?" } }
    end
    question = Question.last
    assert_equal @owner, question.asker
    assert_redirected_to question_url(question)

    follow_redirect!
    assert_select "h1", text: "What was her mother called?"
    assert_select "input[readonly][value=?]", question_link_url(question.token)
    assert_select "[data-controller=share][data-share-url-value=?]", question_link_url(question.token)
  end

  test "a photo gets its own question, asking who is in it" do
    photo = @person.photos.create!(image: image)

    get person_url(@person)
    assert_select "##{dom_id(photo)} a[href=?]", new_person_question_path(@person, photo_id: photo.id)

    get new_person_question_url(@person, photo_id: photo.id)
    assert_select "textarea[name='question[body]']", text: I18n.t("questions.photo_default")
    assert_select "input[type=hidden][name='question[photo_id]'][value=?]", photo.id.to_s

    post person_questions_url(@person), params: { question: { body: "Who is this?", photo_id: photo.id } }
    assert_equal photo, Question.last.photo
  end

  test "open questions show on the profile and in one list" do
    open   = @person.questions.create!(asker: @owner, body: "Where was she born?")
    closed = @person.questions.create!(asker: @owner, body: "Her maiden name?", closed_at: Time.current)

    get person_url(@person)
    assert_select "#questions a[href=?]", question_path(open)
    assert_select "#questions a[href=?]", question_path(closed), count: 0

    get questions_url
    assert_select "#open_questions a[href=?]", question_path(open)
    assert_select "#closed_questions a[href=?]", question_path(closed)
  end

  test "the account menu leads to the questions" do
    get root_url
    assert_select ".account-menu a[href=?]", questions_path
  end

  test "a member answers in the app and an editor writes the answer into the tree in one step" do
    question = @person.questions.create!(asker: @owner, body: "Her real first name?")

    post question_answers_url(question), params: { answer: { body: "Anna" } }
    answer = question.answers.last
    assert_equal @owner, answer.user
    assert_redirected_to question_url(question, anchor: dom_id(answer))

    get new_question_acceptance_url(question, answer_id: answer.id)
    assert_select "turbo-frame##{dom_id(answer, :acceptance)} form" do
      assert_select "select[name=into] option[value=given_names]"
      assert_select "input[name=text][value=Anna]"
    end

    post question_acceptances_url(question), params: { answer_id: answer.id, into: "given_names", text: "Anna" }
    assert_redirected_to person_url(@person)
    assert_equal "Anna", @person.reload.given_names
    assert question.reload.closed?
    assert Edit.edited.where(subject: @person, user: @owner).exists?
  end

  test "an editor closes or deletes a question" do
    question = @person.questions.create!(asker: @owner, body: "Who?")

    post question_closure_url(question)
    assert question.reload.closed?

    assert_difference "Question.count", -1 do
      delete question_url(question)
    end
    assert_redirected_to person_url(@person)
  end

  test "a viewer may answer but not ask, accept or close" do
    question = @person.questions.create!(asker: @owner, body: "Who?")
    viewer = User.create!(name: "Viewer", email_address: "viewer@example.com", password: "password")
    TreeMembership.create!(user: viewer, tree: @tree, role: "viewer")
    sign_in_as viewer

    get question_url(question)
    assert_select "form[action=?]", question_answers_path(question)
    assert_select "a[href^=?]", new_question_acceptance_path(question), count: 0

    post question_answers_url(question), params: { answer: { body: "I don't know" } }
    assert_equal viewer, question.answers.last.user

    post person_questions_url(@person), params: { question: { body: "Me?" } }
    assert_response :forbidden
    post question_closure_url(question)
    assert_response :forbidden
    post question_acceptances_url(question), params: { answer_id: question.answers.last.id, into: "surname", text: "x" }
    assert_response :forbidden
  end

  test "another tree's questions are out of reach" do
    stranger = trees(:beta).people.create!(given_names: "Else")
    question = stranger.questions.create!(asker: users(:two), body: "Who?")

    get question_url(question)
    assert_response :not_found
  end

  private
    def image
      { io: file_fixture("avatar.png").open, filename: "print.png", content_type: "image/png" }
    end
end
