require "test_helper"

class GuestAnswers::CardsControllerTest < ActionDispatch::IntegrationTest
  setup do
    person = trees(:alpha).people.create!(given_names: "Vera", surname: "Ivanova", sex: "F")
    @question = person.questions.create!(asker: users(:one), body: "What was her mother called?")
  end

  test "a relative's link has a preview image without signing in" do
    get question_link_card_url(@question.token, format: :png)
    assert_response :success
    assert_equal "image/png", response.media_type
  end

  test "a wrong token has no card" do
    get question_link_card_url("nope", format: :png)
    assert_response :not_found
  end
end
