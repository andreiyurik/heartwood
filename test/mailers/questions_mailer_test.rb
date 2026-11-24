require "test_helper"

class QuestionsMailerTest < ActionMailer::TestCase
  include Rails.application.routes.url_helpers

  def default_url_options = Rails.application.config.action_mailer.default_url_options

  setup do
    @asker    = users(:one)
    @person   = trees(:alpha).people.create!(given_names: "Vera")
    @question = @person.questions.create!(asker: @asker, body: "What was her mother called?")
  end

  test "the asker hears about a new answer at once, with the answer and a way to stop such letters" do
    answer = nil
    assert_enqueued_emails 1 do
      answer = @question.answers.create!(author_name: "Aunt Masha", body: "Anna Petrovna")
    end

    mail = QuestionsMailer.answered(answer)
    assert_equal [ @asker.email_address ], mail.to
    body = mail.html_part.body.to_s
    assert_match "What was her mother called?", body
    assert_match "Aunt Masha", body
    assert_match "Anna Petrovna", body
    assert_match question_url(@question, tree: @question.tree_id), body
    assert_match letter_unsubscribe_url("answers", ""), body
    assert_equal "List-Unsubscribe=One-Click", mail.header["List-Unsubscribe-Post"].to_s
  end

  test "no letter for your own answer, a burst of answers, or when switched off" do
    assert_no_enqueued_emails do
      @question.answers.create!(user: @asker, body: "Thinking aloud")
    end

    @question.answers.create!(author_name: "A", body: "1")
    assert_no_enqueued_emails do
      @question.answers.create!(author_name: "B", body: "2")
    end

    travel 2.hours do
      @asker.update!(answer_emails: false)
      assert_no_enqueued_emails do
        @question.answers.create!(author_name: "C", body: "3")
      end
    end
  end

  test "the letter says a photo came with the answer" do
    answer = @question.answers.create!(author_name: "Aunt Masha",
      photo: { io: file_fixture("avatar.png").open, filename: "avatar.png", content_type: "image/png" })
    assert_match I18n.t("questions_mailer.answered.photo"), QuestionsMailer.answered(answer).text_part.body.to_s
  end
end
