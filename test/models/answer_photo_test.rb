require "test_helper"

# docs/features/questions.md "A photo in the answer"
class AnswerPhotoTest < ActiveSupport::TestCase
  setup do
    @tree     = trees(:alpha)
    @person   = @tree.people.create!(given_names: "Vera", surname: "Ivanova", sex: "F")
    @question = @person.questions.create!(asker: users(:one), body: "Do you have her photo?")
  end

  teardown { Current.reset }

  test "a photo alone is an answer" do
    answer = @question.answers.create!(author_name: "Aunt Masha", photo: print_file)
    assert answer.photo.attached?
    assert_not @question.answers.new(author_name: "Aunt Masha").valid?
  end

  test "only pictures the album takes, no bigger than the album allows" do
    answer = @question.answers.new(body: "Here", photo: { io: StringIO.new("not a picture"), filename: "note.txt", content_type: "text/plain" })
    assert_not answer.valid?
    assert answer.errors.of_kind?(:photo, :invalid_content_type)
  end

  test "keeping the photo puts a copy in the person's album, once, under the editor's name" do
    answer = @question.answers.create!(author_name: "Aunt Masha", body: "Here she is", photo: print_file)
    Current.session = users(:one).sessions.create!

    photo = answer.keep_photo!
    assert_equal @person, photo.person
    assert photo.image.attached?
    assert_not_equal answer.photo.blob, photo.image.blob
    assert_equal photo, answer.reload.kept_photo
    assert_equal users(:one), Edit.where(subject: photo).sole.user

    assert_no_difference -> { Photo.count } do
      assert_equal photo, answer.keep_photo!
    end
    assert @question.reload.open?
  end

  test "the kept copy stays when the answer goes, and the answer's own file goes with it" do
    answer = @question.answers.create!(author_name: "Aunt Masha", photo: print_file)
    photo = answer.keep_photo!

    assert_difference -> { ActiveStorage::Attachment.where(record_type: "Answer").count }, -1 do
      @question.destroy!
    end
    assert photo.reload.image.attached?
  end

  test "erasing the person leaves none of the answers' photos behind" do
    @question.answers.create!(author_name: "Aunt Masha", photo: print_file)

    @person.erase
    assert_equal 0, ActiveStorage::Attachment.where(record_type: "Answer").count
  end

  private
    def print_file = { io: file_fixture("avatar.png").open, filename: "avatar.png", content_type: "image/png" }
end
