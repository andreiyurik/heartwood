require "test_helper"

class AccountDeletionTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper

  setup do
    @tree = trees(:bach)
    @owner = users(:bach)
    Current.session = @owner.sessions.create!
    Current.tree = @tree
  end

  test "signing up with consent stamps when and which edition was agreed to" do
    user = User.sign_up!({ name: "Ann", email_address: "ann@example.com", password: "password", privacy_consent: "1" })

    assert_in_delta Time.current, user.privacy_consented_at, 1.second
    assert_equal Legal::VERSION, user.privacy_consent_version
  end

  test "signing up without consent is refused, whether unticked or missing" do
    [ "0", nil ].each do |consent|
      error = assert_raises(ActiveRecord::RecordInvalid) do
        User.sign_up!({ name: "Ann", email_address: "ann@example.com", password: "password", privacy_consent: consent })
      end
      assert error.record.errors[:privacy_consent].any?
    end
    assert_not User.exists?(email_address: "ann@example.com")
  end

  test "incinerating a tree removes all of its data and every photo" do
    photos = [ people(:johann_sebastian), Person.create!(given_names: "Gone", sex: "U", tree: @tree) ]
      .map { attach_photo(it).blob }
    Person.find_by!(given_names: "Gone").destroy!

    perform_enqueued_jobs { @tree.incinerate }

    assert_not Tree.exists?(@tree.id)
    assert_equal 0, Person.where(tree_id: @tree.id).count
    assert_equal 0, Event.where(tree_id: @tree.id).count
    assert_equal 0, Edit.where(tree_id: @tree.id).count
    photos.each { assert_not ActiveStorage::Blob.exists?(it.id) }
  end

  test "deleting an account incinerates the trees it owns and keeps the ones it joined" do
    joined = trees(:alpha)
    TreeMembership.create!(user: @owner, tree: joined, role: "editor")
    Current.set(tree: joined) { Person.create!(given_names: "Kept", sex: "U") }
    authored = joined.edits.last

    perform_enqueued_jobs { @owner.destroy! }

    assert_not User.exists?(@owner.id)
    assert_not Tree.exists?(@tree.id)
    assert Tree.exists?(joined.id)
    assert_nil authored.reload.user
  end

  test "history older than the retention period is pruned with its kept photos" do
    old = Person.create!(given_names: "Old", sex: "U", tree: @tree)
    old_photo = attach_photo(old).blob
    old.destroy!
    recent = Person.create!(given_names: "Recent", sex: "U", tree: @tree)
    recent_photo = attach_photo(recent).blob

    travel Edit::RETENTION + 1.day do
      recent.destroy!
      perform_enqueued_jobs { Edit.prune }
    end

    assert_not Edit.exists?(subject_type: "Person", subject_id: old.id)
    assert Edit.exists?(subject_type: "Person", subject_id: recent.id, action: "removed")
    assert_not ActiveStorage::Blob.exists?(old_photo.id)
    assert ActiveStorage::Blob.exists?(recent_photo.id)
  end

  private
    def attach_photo(person)
      person.avatar.attach(io: StringIO.new("\x89PNG\r\n\x1a\n" + "\x00" * 100), filename: "p.png", content_type: "image/png")
      person.avatar
    end
end
