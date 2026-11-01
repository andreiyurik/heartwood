require "test_helper"

class ShareLinkTest < ActiveSupport::TestCase
  test "a tree has at most one view link, with a long random token" do
    tree = trees(:bach)
    link = tree.create_share_link!

    assert_operator link.token.length, :>=, 24
    assert_not_equal tree.join_code, link.token
    assert_raises(ActiveRecord::RecordNotUnique) { ShareLink.create!(tree: tree) }
  end

  test "renewing the link kills the old URL" do
    link = trees(:bach).create_share_link!
    old  = link.token

    link.renew!

    assert_not_equal old, link.reload.token
    assert_nil ShareLink.find_by(token: old)
  end

  test "it goes away with its tree" do
    tree = trees(:bach)
    tree.create_share_link!

    assert_difference -> { ShareLink.count }, -1 do
      tree.destroy!
    end
  end
end
