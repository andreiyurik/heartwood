require "test_helper"

# Cross-tenant isolation: user A must not read user B's data.
# Every enumeration and direct find must be tree-scoped.
class TenancyTest < ActionDispatch::IntegrationTest
  setup do
    # user :one owns tree :alpha
    @tree_a   = trees(:alpha)
    @person_a = Person.create!(given_names: "Alice", surname: "Alpha", sex: "F", tree: @tree_a)
    @event_a  = Event.create!(kind: "BIRT", eventable: @person_a, tree: @tree_a)

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

  # --- PATCH / DELETE people: cross-tenant mutation returns 404, data untouched ---

  test "user B cannot update user A's person" do
    sign_in_as users(:two)
    patch person_url(@person_a), params: { person: { given_names: "Hacked" } }
    assert_response :not_found
    assert_equal "Alice", @person_a.reload.given_names
  end

  test "user B cannot delete user A's person" do
    sign_in_as users(:two)
    delete person_url(@person_a)
    assert_response :not_found
    assert @person_a.reload.persisted?
  end

  # --- Events: cross-tenant create / update / delete returns 404 ---

  test "user B cannot create an event on user A's person" do
    sign_in_as users(:two)
    assert_no_difference "Event.count" do
      post person_events_url(@person_a), params: { event: { kind: "DEAT" } }
    end
    assert_response :not_found
  end

  test "user B cannot update user A's event" do
    sign_in_as users(:two)
    patch person_event_url(@person_a, @event_a), params: { event: { date_raw: "1 JAN 1900" } }
    assert_response :not_found
    assert_nil @event_a.reload.date_raw
  end

  test "user B cannot delete user A's event" do
    sign_in_as users(:two)
    assert_no_difference "Event.count" do
      delete person_event_url(@person_a, @event_a)
    end
    assert_response :not_found
  end

  # --- Relatives: cross-tenant create returns 404, no record created ---

  test "user B cannot add a relative to user A's person" do
    sign_in_as users(:two)
    assert_no_difference "Person.count" do
      post person_relatives_url(@person_a),
           params: { relation: "child", person: { given_names: "Stolen", sex: "U" } }
    end
    assert_response :not_found
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
