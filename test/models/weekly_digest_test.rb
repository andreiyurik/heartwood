require "test_helper"

class WeeklyDigestTest < ActiveSupport::TestCase
  include ActionMailer::TestHelper

  setup do
    @tree   = trees(:alpha)
    @owner  = users(:one)
    @cousin = User.create!(name: "Masha", email_address: "masha@example.com", password: "password")
    @cousin_membership = TreeMembership.create!(user: @cousin, tree: @tree, role: "editor")
    @owner_membership  = tree_memberships(:one_alpha)
  end

  teardown { Current.reset }

  test "what others did this week is news; your own edits are not" do
    as(@cousin) { @tree.people.create!(given_names: "Vera", surname: "Ivanova") }

    assert WeeklyDigest.new(@owner_membership).news?
    assert_not WeeklyDigest.new(@cousin_membership).news?
    assert_equal [ "Vera Ivanova" ], WeeklyDigest.new(@owner_membership).added_people.map(&:display_name)
    assert_equal [ "Masha" ], WeeklyDigest.new(@owner_membership).contributors
  end

  test "what someone did before deleting their account is still news" do
    as(@cousin) { @tree.people.create!(given_names: "Vera") }
    @cousin.destroy!
    assert WeeklyDigest.new(@owner_membership).news?
  end

  test "last week's news is old news" do
    travel_to 10.days.ago do
      as(@cousin) { @tree.people.create!(given_names: "Vera") }
    end

    assert_not WeeklyDigest.new(@owner_membership).news?
  end

  test "changes, photos, comments and answers are counted; open questions are listed" do
    person = @tree.people.create!(given_names: "Vera")
    as(@cousin) do
      person.update!(surname: "Ivanova")
      person.photos.create!(image: { io: file_fixture("avatar.png").open, filename: "p.png", content_type: "image/png" })
    end
    person.comments.create!(user: @cousin, body: "Looks right")
    question = person.questions.create!(asker: @cousin, body: "Who?")
    question.answers.create!(author_name: "Aunt", body: "Me")

    digest = WeeklyDigest.new(@owner_membership)
    assert_equal 1, digest.changes_count
    assert_equal 1, digest.photos_count
    assert_equal 1, digest.comments_count
    assert_equal 1, digest.answers_count
    assert_equal [ question ], digest.open_questions
  end

  test "an open question alone is not news" do
    @tree.people.create!(given_names: "Vera").questions.create!(asker: @cousin, body: "Who?")
    assert_not WeeklyDigest.new(@owner_membership).news?
  end

  test "letters go only to members with news who haven't switched them off" do
    as(@cousin) { @tree.people.create!(given_names: "Vera") }

    assert_enqueued_emails 1 do
      WeeklyDigest.deliver_all
    end

    @owner.update!(weekly_digest: false)
    assert_no_enqueued_emails do
      WeeklyDigest.deliver_all
    end
  end

  private
    def as(user)
      Current.session = user.sessions.create!
      yield
    ensure
      Current.reset
    end
end
