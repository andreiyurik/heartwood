class TreeMembership < ApplicationRecord
  belongs_to :tree
  belongs_to :user

  enum :role, %w[owner editor viewer].index_by(&:itself), default: "owner", validate: true

  validates :user_id, uniqueness: { scope: :tree_id }

  def can_edit? = owner? || editor?
end
