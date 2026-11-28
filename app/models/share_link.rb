# A read-only link to a tree for people without an account. Never grants membership; see [[privacy-access]].
class ShareLink < ApplicationRecord
  belongs_to :tree
  has_secure_token :token, length: 32

  scope :of_owner, ->(email) { joins(tree: { tree_memberships: :user }).where(tree_memberships: { role: "owner" }, users: { email_address: email }) }

  def renew!
    regenerate_token
  end

  def people
    tree.people.visible_to(nil)
  end
end
