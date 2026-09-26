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
          user: { name: "Fresh Signup", email_address: "fresh@example.com", password: "password123" } }
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

  test "unknown join code 404s" do
    post session_url, params: { email_address: users(:one).email_address, password: "password" }
    get join_url("NOPE-0000-CODE")
    assert_response :not_found
  end
end
