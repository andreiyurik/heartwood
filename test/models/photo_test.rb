require "test_helper"

class PhotoTest < ActiveSupport::TestCase
  setup do
    @person = Person.create!(given_names: "Ada", surname: "Lovelace", sex: "F", tree: trees(:alpha))
  end

  test "a photo belongs to a person and takes the person's tree" do
    photo = @person.photos.create!(image: image, caption: "At the piano", taken: "1836")

    assert_equal trees(:alpha), photo.tree
    assert_equal "At the piano", photo.caption
    assert photo.image.attached?
  end

  test "only images of a sane size are accepted" do
    photo = @person.photos.build(image: { io: StringIO.new("not an image"), filename: "notes.txt", content_type: "text/plain" })
    assert_not photo.valid?
    assert photo.errors.added?(:image, :invalid_content_type)

    assert_not @person.photos.build.valid?
  end

  test "the album is ordered oldest print first, undated last" do
    late    = @person.photos.create!(image: image, taken: "1850")
    undated = @person.photos.create!(image: image)
    early   = @person.photos.create!(image: image, taken: "about 1820")

    assert_equal [ early, late, undated ], @person.photos.album.to_a
  end

  test "deleting a person takes the album along" do
    @person.photos.create!(image: image)
    assert_difference "Photo.count", -1 do
      @person.destroy!
    end
  end

  private
    def image
      { io: file_fixture("avatar.png").open, filename: "avatar.png", content_type: "image/png" }
    end
end
