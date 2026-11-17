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
