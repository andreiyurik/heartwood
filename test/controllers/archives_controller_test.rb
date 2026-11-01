require "test_helper"

class ArchivesControllerTest < ActionDispatch::IntegrationTest
  include ActiveJob::TestHelper

  setup do
    @tree = trees(:alpha)
    sign_in_as users(:one)
  end

  test "create queues an archive of the current tree and shows its progress" do
    assert_enqueued_with(job: ArchiveJob) do
      assert_difference -> { @tree.archives.count }, 1 do
        post archives_url
      end
    end

    archive = @tree.archives.last
    assert_equal users(:one), archive.user
    assert_redirected_to archive_url(archive)

    follow_redirect!
    assert_select "turbo-cable-stream-source"
  end

  test "a ready archive offers its download" do
    archive = @tree.archives.create!(user: users(:one))
    perform_enqueued_jobs { archive.build_later }

    get archive_url(archive)

    assert_response :success
    assert_select "a[href*='/rails/active_storage/blobs/'][href*='disposition=attachment']"
  end

  test "nobody else can open someone's archive" do
    archive = @tree.archives.create!(user: users(:one))
    TreeMembership.create!(user: users(:two), tree: @tree, role: "editor")

    sign_out
    sign_in_as users(:two)
    get archive_url(archive)

    assert_response :not_found
  end

  test "the menu offers the archive next to the plain GEDCOM" do
    @tree.people.create!(given_names: "Anna")
    get people_url

    assert_select "form[action=?]", archives_path
    assert_select "form[action=?]", export_path
  end
end
