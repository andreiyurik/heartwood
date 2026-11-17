require "test_helper"

class GuestAnswersControllerTest < ActionDispatch::IntegrationTest
  setup do
    @tree     = trees(:alpha)
    @asker    = users(:one)
    @deceased = @tree.people.create!(given_names: "Vera", surname: "Ivanova", sex: "F")
    @deceased.events.create!(kind: "DEAT", date_raw: "1990")
    @living   = @tree.people.create!(given_names: "Lina", surname: "Petrova", sex: "F")
  end

  test "a relative without an account reads the question and answers it" do
    question = @deceased.questions.create!(asker: @asker, body: "What was her mother called?")

    get question_link_url(question.token)
    assert_response :success
    assert_select "h1", text: "What was her mother called?"
    assert_match @asker.name, response.body
    assert_match "Vera Ivanova", response.body
    assert_equal "noindex, nofollow", response.headers["X-Robots-Tag"]
    assert_equal "no-referrer", response.headers["Referrer-Policy"]
    assert_select "meta[property='og:image'][content=?]", question_link_card_url(question.token, format: :png)

    assert_difference "question.answers.count" do
      post question_link_url(question.token), params: { answer: { body: "Anna Petrovna", author_name: "Aunt Masha" } }
    end
    assert_redirected_to question_link_url(question.token)
    assert_equal [ nil, "Aunt Masha", "Anna Petrovna" ], question.answers.last.values_at(:user_id, :author_name, :body)

    follow_redirect!
    assert_select ".answered", text: /#{I18n.t("guest_answers.thanks")}/
  end

  test "a living person stays out of the page; only the question's words are there" do
    question = @living.questions.create!(asker: @asker, body: "Where did she study?")

    get question_link_url(question.token)
    assert_response :success
    assert_no_match "Lina", response.body
    assert_no_match "Petrova", response.body
  end

  test "the photo a question is about is shown, but nothing else of the album" do
    photo = @living.photos.create!(image: image, caption: "Lina in Sochi")
    other = @living.photos.create!(image: image)
    question = @living.questions.create!(asker: @asker, photo: photo)

    get question_link_url(question.token)
    assert_select "img.question-photo", 1
    assert_no_match other.image.blob.signed_id, response.body
    assert_no_match "Lina in Sochi", response.body
  end

  test "an empty answer is sent back, a closed question takes no more" do
    question = @deceased.questions.create!(asker: @asker, body: "Who?")

    post question_link_url(question.token), params: { answer: { body: " " } }
    assert_response :unprocessable_entity

    question.close(by: @asker)
    get question_link_url(question.token)
    assert_select "form textarea", count: 0
    assert_no_difference "Answer.count" do
      post question_link_url(question.token), params: { answer: { body: "Late" } }
    end
  end

  test "a wrong link says so" do
    get question_link_url("nope")
    assert_response :not_found
  end

  test "a member who opens the link goes to the question in the app" do
    question = @deceased.questions.create!(asker: @asker, body: "Who?")
    sign_in_as @asker

    get question_link_url(question.token)
    assert_redirected_to question_url(question)
  end

  private
    def image
      { io: file_fixture("avatar.png").open, filename: "print.png", content_type: "image/png" }
    end
end
