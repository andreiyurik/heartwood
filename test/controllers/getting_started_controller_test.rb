require "test_helper"

# docs/features/getting-started.md
class GettingStartedControllerTest < ActionDispatch::IntegrationTest
  setup do
    @tree, @owner = trees(:alpha), users(:one)
    @tree.people.destroy_all
    sign_in_as @owner
  end

  test "an empty tree asks for its first person and nothing else" do
    get people_url
    assert_select ".blank-slate"
    assert_select ".getting-started", count: 0
  end

  test "with the first person in, the three steps appear, the next one with its button" do
    me = @tree.people.create!(given_names: "Аня")

    get people_url
    assert_select ".getting-started" do
      assert_select "h2", I18n.t("getting_started.title")
      assert_select ".getting-started__step--done", 1
      assert_select "a.btn[href=?]", new_person_relative_path(me, relation: "parent"), 1
      assert_select "a.btn", 1
    end
  end

  test "hiding it puts it away for this member for good" do
    @tree.people.create!(given_names: "Аня")

    delete getting_started_url
    assert_redirected_to people_url

    get people_url
    assert_select ".getting-started", count: 0
  end

  test "it is gone once all three are done" do
    me = @tree.people.create!(given_names: "Аня")
    me.add_parent(@tree.people.create!(given_names: "Иван")).add_parent(@tree.people.create!(given_names: "Пётр"))
    me.questions.create!(asker: @owner, body: "Кто?")

    get people_url
    assert_select ".getting-started", count: 0
  end

  test "a viewer has no steps to take" do
    @tree.people.create!(given_names: "Аня")
    viewer = User.create!(name: "Viewer", email_address: "viewer@example.com", password: "password")
    @tree.tree_memberships.create!(user: viewer, role: "viewer")
    sign_in_as viewer

    get people_url
    assert_select ".getting-started", count: 0
  end
end
