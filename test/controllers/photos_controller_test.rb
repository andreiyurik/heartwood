require "test_helper"

class PhotosControllerTest < ActionDispatch::IntegrationTest
  setup do
    @tree   = trees(:alpha)
    @person = Person.create!(given_names: "Ada", surname: "Lovelace", sex: "F", tree: @tree)
    sign_in_as users(:one)
  end

  test "an editor adds several photos at once" do
    assert_difference "@person.photos.count", 2 do
      post person_photos_url(@person), params: { photos: [ upload, upload ] }
    end
    assert_redirected_to person_url(@person, anchor: "memories")
  end

  test "the album shows every print with its caption and opens it full size" do
    photo = @person.photos.create!(image: blob, caption: "At the piano", taken: "1836")

    get person_url(@person)
    assert_select "#memories .photo-grid figure##{dom_id(photo)}" do
      assert_select "a[data-action='lightbox#open'] img[alt='At the piano']"
      assert_select "figcaption", text: /At the piano/
      assert_select "figcaption", text: /1836/
    end
    assert_select "dialog.lightbox"
    assert_select "#memories form[action=?] input[type=file][multiple]", person_photos_path(@person)
  end

  test "a caption is edited in place" do
    photo = @person.photos.create!(image: blob)

    get edit_person_photo_url(@person, photo)
    assert_select "turbo-frame##{dom_id(photo, :caption)} form input[name='photo[caption]']"

    patch person_photo_url(@person, photo), params: { photo: { caption: "Grandmother's wedding", taken: "1954" } }
    assert_redirected_to person_url(@person, anchor: dom_id(photo))
    assert_equal [ "Grandmother's wedding", "1954" ], photo.reload.values_at(:caption, :taken)
  end

  test "a photo can be removed" do
    photo = @person.photos.create!(image: blob)
    assert_difference "Photo.count", -1 do
      delete person_photo_url(@person, photo)
    end
  end

  test "a wrong file is refused with a reason" do
    assert_no_difference "Photo.count" do
      post person_photos_url(@person), params: { photos: [ Rack::Test::UploadedFile.new(Rails.root.join("test/fixtures/gedcom/minimal_551.ged"), "text/plain") ] }
    end
    assert_redirected_to person_url(@person, anchor: "memories")
    follow_redirect!
    assert_select ".flash--alert"
  end

  test "a viewer sees the album but cannot change it" do
    photo  = @person.photos.create!(image: blob)
    viewer = User.create!(name: "Viewer", email_address: "viewer@example.com", password: "password")
    TreeMembership.create!(user: viewer, tree: @tree, role: "viewer")
    sign_in_as viewer

    get person_url(@person)
    assert_select "#memories figure##{dom_id(photo)}"
    assert_select "#memories input[type=file]", count: 0

    post person_photos_url(@person), params: { photos: [ upload ] }
    assert_response :forbidden
    delete person_photo_url(@person, photo)
    assert_response :forbidden
  end

  test "another tree's photos are out of reach" do
    stranger = Person.create!(given_names: "Else", sex: "U", tree: trees(:beta))
    photo    = stranger.photos.create!(image: blob)

    delete person_photo_url(stranger, photo)
    assert_response :not_found
  end

  private
    def upload = fixture_file_upload("avatar.png", "image/png")
    def blob   = { io: file_fixture("avatar.png").open, filename: "avatar.png", content_type: "image/png" }
end
