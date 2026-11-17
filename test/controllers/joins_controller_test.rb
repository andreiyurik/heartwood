require "test_helper"

# GET/POST /join/:join_code — see [[collaboration]].
class JoinsControllerTest < ActionDispatch::IntegrationTest
  setup { @tree = trees(:beta) }

  test "a guest sees the tree name and a sign-up form" do
    get join_url(@tree.join_code)
    assert_response :success
    assert_select "h1", /#{@tree.name}/
    assert_select "form[action=?]", join_path(@tree.join_code) do
      assert_select "input[name='user[name]']"
      assert_select "input[name='user[email_address]']"
      assert_select "input[name='user[password]']"
    end
    assert_select "a[href=?]", new_session_path
  end

  test "a guest signing up through the link gets an account and an editor seat in one request" do
    assert_difference [ "User.count", "TreeMembership.count" ], 1 do
      assert_no_difference "Tree.count" do
        post join_path(@tree.join_code), params: {
          user: { name: "Fresh Signup", email_address: "fresh@example.com", password: "password123", privacy_consent: "1" } }
      end
    end
    assert_redirected_to root_url

    user = User.find_by!(email_address: "fresh@example.com")
    assert user.tree_memberships.exists?(tree: @tree, role: "editor")

    follow_redirect!
    assert_select "#header", /#{@tree.name}/
  end

  test "a guest with invalid details sees the form again and joins nothing" do
    assert_no_difference [ "User.count", "TreeMembership.count" ] do
      post join_path(@tree.join_code), params: { user: { name: "", email_address: "nope", password: "x" } }
    end
    assert_response :unprocessable_entity
  end

  test "a guest who signs in instead lands back on the join page" do
    get join_url(@tree.join_code)
    user = User.create!(name: "Newcomer", email_address: "newcomer@example.com", password: "password")
    post session_url, params: { email_address: user.email_address, password: "password" }
    assert_redirected_to join_url(@tree.join_code)
  end

  test "an existing user with their own tree can sign in and join a second one" do
    owner = users(:one) # already owns trees(:alpha)
    get join_url(@tree.join_code)
    post session_url, params: { email_address: owner.email_address, password: "password" }
    follow_redirect!

    assert_difference "owner.tree_memberships.count", 1 do
      post join_path(@tree.join_code)
    end
    assert_redirected_to root_url
    assert owner.tree_memberships.exists?(tree: @tree, role: "editor")
    # still a member of their own tree too
    assert owner.tree_memberships.exists?(tree: trees(:alpha), role: "owner")
  end

  test "already a member gets redirected with a notice instead of the confirm page" do
    post session_url, params: { email_address: users(:one).email_address, password: "password" }
    get join_url(trees(:alpha).join_code)
    assert_redirected_to root_url
  end

  test "joining switches the active tree" do
    owner = users(:one)
    post session_url, params: { email_address: owner.email_address, password: "password" }
    post join_path(@tree.join_code)

    get people_url
    assert_match(@tree.name, @response.body)
  end

  test "an old or mistyped link says so kindly instead of a bare 404" do
    get join_url("NOPE-0000-CODE")
    assert_response :not_found
    assert_select "h1", I18n.t("joins.expired.title")
    assert_select "p", I18n.t("joins.expired.lede")
    assert_select "main form", count: 0

    post join_path("NOPE-0000-CODE")
    assert_response :not_found
  end

  test "the invitation says who is calling and what is inside" do
    Person.create!(given_names: "Ada", surname: "Lovelace", sex: "F", tree: @tree)
    get join_url(@tree.join_code)
    assert_select ".invitation", text: /#{users(:two).name}/
    assert_select ".invitation svg.crest"
    assert_select ".invitation__meta", text: /1 person/
  end

  test "joining as a new person also asks for consent" do
    get join_url(@tree.join_code)
    assert_select "input[type=checkbox][name='user[privacy_consent]'][required]"

    assert_no_difference "User.count" do
      post join_path(@tree.join_code), params: { user: { name: "No Consent", email_address: "nc@example.com", password: "password123" } }
    end
    assert_response :unprocessable_entity
  end
end
