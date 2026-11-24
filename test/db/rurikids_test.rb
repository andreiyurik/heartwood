require "test_helper"
require Rails.root.join("db/demo/rurikids")

# The landing's example tree (docs/features/landing.md): the same one in development and on the hosted service.
class RurikidsTest < ActiveSupport::TestCase
  setup { @owner = User.create!(name: "Demo", email_address: "demo@example.com", password: SecureRandom.base58(24)) }

  test "builds the Rurikids from Rurik to Monomakh, with portraits, sources and a view link" do
    tree = Rurikids.build!(owner: @owner)

    assert_equal "Рюриковичи", tree.name
    assert tree.tree_memberships.exists?(user: @owner, role: "owner")
    assert_equal 19, tree.people.count
    assert tree.people.find_by!(given_names: "Ярослав Владимирович").avatar.attached?
    assert tree.sources.exists?(title: "Повесть временных лет")
    assert tree.share_link
  end

  test "a guest on the view link sees every one of them: no one in it is living" do
    tree = Rurikids.build!(owner: @owner)
    assert_equal tree.people.count, tree.share_link.people.count
  end

  test "building it again changes nothing" do
    tree = Rurikids.build!(owner: @owner)
    assert_no_difference -> { Person.count + Event.count + Source.count + Citation.count + ShareLink.count } do
      assert_equal tree, Rurikids.build!(owner: @owner)
    end
  end
end
