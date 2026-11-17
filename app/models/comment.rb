class Comment < ApplicationRecord
  belongs_to :tree, default: -> { person&.tree }
  belongs_to :person
  belongs_to :user, optional: true

  broadcasts_refreshes_to :tree

  validates :body, presence: true, length: { maximum: 5_000 }

  scope :chronological, -> { order(:created_at, :id) }

  def author = user&.name || I18n.t("edits.deleted_user")

  def editable_by?(someone) = user.present? && user == someone

  def deletable_by?(someone)
    editable_by?(someone) || tree.tree_memberships.exists?(user: someone, role: "owner")
  end
end
