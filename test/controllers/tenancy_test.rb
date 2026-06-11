require "test_helper"

# Cross-tenant isolation: user A must not read user B's data.
# Every enumeration and direct find must be tree-scoped.
class TenancyTest < ActionDispatch::IntegrationTest
  setup do
    # user :one owns tree :alpha
    @tree_a  = trees(:alpha)
    @person_a = Person.create!(given_names: "Alice", surname: "Alpha", sex: "F", tree: @tree_a)

    # user :two owns tree :beta — no people in it yet
    @tree_b = trees(:beta)
  end

  # --- index is scoped to Current.tree ---

  test "index shows only the signed-in user's tree people" do
    Person.create!(given_names: "Bob", surname: "Beta", sex: "M", tree: @tree_b)

    sign_in_as users(:one)
    get people_url
    assert_response :success
    assert_select "body", /Alice/
    assert_select "body", text: /Bob/, count: 0
  end

  # --- show / tree / events: cross-tenant access returns 404 ---

  test "user B cannot show user A's person" do
    sign_in_as users(:two)
    get person_url(@person_a)
    assert_response :not_found
  end

  test "user B cannot view the tree for user A's person" do
    sign_in_as users(:two)
    get person_tree_url(@person_a)
    assert_response :not_found
  end

  test "user B cannot access events of user A's person" do
    sign_in_as users(:two)
    get new_person_event_url(@person_a)
    assert_response :not_found
  end

  test "user A can access their own person" do
    sign_in_as users(:one)
    get person_url(@person_a)
    assert_response :success
  end

  # --- new user gets a bootstrap tree on first request ---

  test "a new user with no tree gets one bootstrapped automatically" do
    new_user = User.create!(email_address: "new@example.com", password: "password123")
    sign_in_as new_user
    get people_url
    assert_response :success
    assert new_user.trees.exists?, "bootstrap tree should be created"
  end
end
