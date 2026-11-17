require "test_helper"

class DigestMailerTest < ActionMailer::TestCase
  include Rails.application.routes.url_helpers

  def default_url_options = Rails.application.config.action_mailer.default_url_options
  setup do
    @tree   = trees(:alpha)
    @owner  = users(:one)
    @cousin = User.create!(name: "Masha", email_address: "masha@example.com", password: "password")
    TreeMembership.create!(user: @cousin, tree: @tree, role: "editor")
    Current.session = @cousin.sessions.create!
    @vera = @tree.people.create!(given_names: "Vera", surname: "Ivanova")
    @question = @vera.questions.create!(asker: @cousin, body: "What was her mother called?")
    Current.reset
  end

  test "the letter names who added whom, links to them and to open questions" do
    mail = DigestMailer.weekly(tree_memberships(:one_alpha))

    assert_equal [ @owner.email_address ], mail.to
    assert_match @tree.name, mail.subject
    body = mail.html_part.body.to_s
    assert_match "Vera Ivanova", body
    assert_match "Masha", body
    assert_match person_url(@vera), body
    assert_match question_url(@question), body
    assert_match "What was her mother called?", body
    assert_match "Vera Ivanova", mail.text_part.body.to_s
  end

  test "one click unsubscribes, in the footer and in the headers" do
    mail = DigestMailer.weekly(tree_memberships(:one_alpha))
    url  = mail.header["List-Unsubscribe"].to_s[/<(.+)>/, 1]

    assert_equal "List-Unsubscribe=One-Click", mail.header["List-Unsubscribe-Post"].to_s
    assert_match url, mail.html_part.body.to_s
    assert_equal @owner, User.find_by_unsubscribe_token("digest", url.split("/").last)
  end

  test "the letter speaks the member's language" do
    @owner.update!(locale: "ru")
    mail = DigestMailer.weekly(tree_memberships(:one_alpha))
    assert_match "Что нового", mail.subject
    assert_no_match(/ and /, mail.html_part.body.to_s)
  end
end
