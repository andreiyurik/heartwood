require "test_helper"

class ConditionalGetTest < ActionDispatch::IntegrationTest
  setup do
    @tree = trees(:alpha)
    sign_in_as users(:one)
  end

  test "an unchanged history page is answered with Not Modified, a changed one is sent again" do
    get edits_url
    etag = response.headers["ETag"]
    assert etag

    get edits_url, headers: { "If-None-Match" => etag }
    assert_response :not_modified

    Current.session = users(:one).sessions.create!
    @tree.people.create!(given_names: "Vera")
    Current.reset
    get edits_url, headers: { "If-None-Match" => etag }
    assert_response :success
  end

  test "closing a question changes the list" do
    question = @tree.people.create!(given_names: "Vera").questions.create!(asker: users(:one), body: "Who?")
    get questions_url
    etag = response.headers["ETag"]

    post question_closure_url(question)
    get questions_url, headers: { "If-None-Match" => etag }
    assert_response :success
  end

  test "renaming a person or removing a photo changes the lists that show them" do
    person = @tree.people.create!(given_names: "Vera")
    person.questions.create!(asker: users(:one), body: "Who?")
    photo = person.photos.create!(image: { io: file_fixture("avatar.png").open, filename: "p.png", content_type: "image/png" })

    get questions_url
    questions_etag = response.headers["ETag"]
    get edits_url
    edits_etag = response.headers["ETag"]

    travel 1.minute do
      person.update!(given_names: "Vera Ivanovna")
      get questions_url, headers: { "If-None-Match" => questions_etag }
      assert_response :success

      photo.destroy!
      get edits_url, headers: { "If-None-Match" => edits_etag }
      assert_response :success
    end
  end

  test "another member gets their own copy" do
    get edits_url
    etag = response.headers["ETag"]

    viewer = User.create!(name: "Viewer", email_address: "viewer@example.com", password: "password")
    TreeMembership.create!(user: viewer, tree: @tree, role: "viewer")
    sign_in_as viewer
    get edits_url, headers: { "If-None-Match" => etag }
    assert_response :success
  end
end
