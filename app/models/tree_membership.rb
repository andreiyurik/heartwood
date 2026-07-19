class TreeMembership < ApplicationRecord
  belongs_to :tree
  belongs_to :user

  validates :role, presence: true
  validates :user_id, uniqueness: { scope: :tree_id }
end
