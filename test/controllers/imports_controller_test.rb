require "test_helper"

class ImportsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @tree = trees(:alpha)
    sign_in_as users(:one)
  end

  def upload(name = "minimal_551.ged")
    fixture_file_upload("../gedcom/#{name}", "text/plain")
  end

  test "new shows an upload form" do
    get new_import_url
    assert_response :success
    assert_select "form[action=?][enctype='multipart/form-data']", import_path do
      assert_select "input[type=file][name='import[file]'][accept*='.ged']"
    end
  end

  test "create stores the file, queues the import and shows progress" do
    assert_enqueued_with(job: ImportJob) do
      assert_difference -> { @tree.imports.count }, 1 do
        post import_url, params: { import: { file: upload } }
      end
    end
    assert_redirected_to import_url
    assert_equal users(:one), @tree.imports.last.user
  end

  test "create without a usable file shows the form again" do
    assert_no_enqueued_jobs do
      post import_url, params: { import: { file: "" } }
    end
    assert_response :unprocessable_entity
    assert_select ".errors"
  end

  test "show reports a completed import" do
    import = @tree.imports.create!(user: users(:one), file: upload)
    import.process

    get import_url
    assert_response :success
    assert_select ".import-report", /2/
    assert_select "a[href=?]", root_path
  end

  test "show explains a failed import" do
    import = @tree.imports.create!(user: users(:one), file: upload)
    import.update!(status: "failed", error: "tree_full")

    get import_url
    assert_select ".import-report", text: /#{I18n.t("imports.show.failed.tree_full")}/
    assert_select "a[href=?]", new_import_path
  end

  test "show while the import runs listens for updates" do
    @tree.imports.create!(user: users(:one), file: upload)
    get import_url
    assert_select "turbo-cable-stream-source"
  end

  test "show without any import sends you to the upload form" do
    get import_url
    assert_redirected_to new_import_url
  end

  test "viewers cannot import" do
    viewer = User.create!(name: "Vi", email_address: "vi@example.com", password: "password")
    TreeMembership.create!(user: viewer, tree: @tree, role: "viewer")
    sign_out
    sign_in_as viewer

    get new_import_url
    assert_response :forbidden
    assert_no_difference -> { Import.count } do
      post import_url, params: { import: { file: upload } }
    end
  end
end
