require "test_helper"

class QuestionTest < ActiveSupport::TestCase
  setup do
    @tree   = trees(:alpha)
    @asker  = users(:one)
    @person = Person.create!(given_names: "Vera", surname: "Ivanova", sex: "F", tree: @tree)
    @photo  = @person.photos.create!(image: image)
    Current.session = @asker.sessions.create!
  end

  teardown { Current.reset }

  test "a question belongs to a person and gets its own link token" do
    question = @person.questions.create!(asker: @asker, body: "What was her mother called?")

    assert_equal @tree, question.tree
    assert_equal 32, question.token.length
    assert question.open?
    assert_equal %w[ given_names surname birth_surname born died ], question.fields
  end

  test "a photo question defaults to asking who is in it and offers the caption" do
    question = @person.questions.build(asker: @asker, photo: @photo)

    assert_equal I18n.t("questions.photo_default"), question.body
    assert_equal %w[ caption taken ], question.fields
  end

  test "an answer written into a name is a person edit in the history and closes the question" do
    question = @person.questions.create!(asker: @asker, body: "Her real first name?")
    answer   = question.answers.create!(author_name: "Aunt Masha", body: "Anna, I think")

    assert_difference -> { Edit.edited.where(subject: @person).count } do
      question.accept(answer, into: "given_names", text: "Anna", by: @asker)
    end

    assert_equal "Anna", @person.reload.given_names
    assert answer.reload.accepted?
    assert question.reload.closed?
    assert_equal @asker, question.closed_by
  end

  test "an answer written into a birth date creates the birth event" do
    question = @person.questions.create!(asker: @asker, body: "When was she born?")
    answer   = question.answers.create!(author_name: "Aunt Masha", body: "1921")

    assert_difference -> { Edit.added.where(subject_type: "Event").count } do
      question.accept(answer, into: "born", text: "1921", by: @asker)
    end
    assert_equal 1921, @person.reload.birth.date_start.year
  end

  test "an answer becomes a photo's caption with a photo edit in the history" do
    question = @person.questions.create!(asker: @asker, photo: @photo)
    answer   = question.answers.create!(author_name: "Uncle Petya", body: "Vera and Kolya at the dacha")

    assert_difference -> { Edit.edited.where(subject: @photo).count } do
      question.accept(answer, into: "caption", text: answer.body, by: @asker)
    end
    assert_equal "Vera and Kolya at the dacha", @photo.reload.caption
    assert_equal @person, Edit.where(subject: @photo).last.person
  end

  test "a field the question doesn't offer is refused" do
    question = @person.questions.create!(asker: @asker, body: "Who?")
    answer   = question.answers.create!(author_name: "Masha", body: "x")

    assert_raises(ArgumentError) { question.accept(answer, into: "private", text: "1", by: @asker) }
    assert question.reload.open?
  end

  test "a question can be closed without writing anything" do
    question = @person.questions.create!(asker: @asker, body: "Who?")
    question.close(by: @asker)

    assert question.closed?
    assert_includes @tree.questions.closed, question
    assert_not_includes @tree.questions.open, question
  end

  test "an answer needs words, and a guest's name is optional" do
    question = @person.questions.create!(asker: @asker, body: "Who?")

    assert_not question.answers.build(body: " ").valid?
    assert question.answers.build(body: "Me").valid?
    assert_equal I18n.t("answers.someone"), question.answers.build(body: "Me").author
    assert_equal @asker.name, question.answers.build(body: "Me", user: @asker).author
  end

  test "questions go with their person and their photo" do
    @person.questions.create!(asker: @asker, body: "Who?")
    @person.questions.create!(asker: @asker, photo: @photo)

    assert_difference "Question.count", -1 do
      @photo.destroy!
    end
    assert_difference "Question.count", -1 do
      @person.destroy!
    end
  end

  test "erasing a person takes their questions and answers along" do
    question = @person.questions.create!(asker: @asker, body: "Who?")
    question.answers.create!(body: "Vera Ivanova, born 1921")

    @person.erase
    assert_equal 0, Answer.count
  end

  private
    def image
      { io: file_fixture("avatar.png").open, filename: "print.png", content_type: "image/png" }
    end
end
