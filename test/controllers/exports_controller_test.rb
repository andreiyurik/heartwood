require "test_helper"

# ExportsController — the GEDCOM download endpoint. Writer semantics live in
# Gedcom::WriterTest; this covers the controller perimeter: auth, send_data headers,
# and that the body is scoped to the signed-in user's Current.tree.
class ExportsControllerTest < ActionDispatch::IntegrationTest
  test "requires authentication" do
    post export_url
    assert_redirected_to new_session_url
  end

  test "exports the current tree as a GEDCOM attachment" do
    sign_in_as users(:bach)
    post export_url

    assert_response :success
    assert_equal "text/plain", response.media_type
    assert_match(/attachment/,  response.headers["Content-Disposition"])
    assert_match(/tree\.ged/,   response.headers["Content-Disposition"])
    assert_match(/\A0 HEAD\n/,  response.body)
    assert_match(/\n0 TRLR\z/,  response.body)
  end

  test "export is scoped to the signed-in user's tree" do
    other = Person.create!(given_names: "Bob", surname: "Beta", sex: "M", tree: trees(:beta))
    Event.create!(kind: "DEAT", eventable: other, tree: trees(:beta))

    sign_in_as users(:bach)
    post export_url

    assert_match "Sebastian", response.body
    assert_no_match(/Beta/, response.body)
  end

  test "a member's export includes their own living people" do
    Person.create!(given_names: "Alive", surname: "Today", sex: "U", tree: trees(:bach))

    sign_in_as users(:bach)
    post export_url
    assert_match "Alive", response.body
  end
end
