class Tree < ApplicationRecord
  has_many :tree_memberships, dependent: :destroy
  has_many :users, through: :tree_memberships
  has_many :people, dependent: :destroy
  has_many :families, dependent: :destroy
  has_many :events, dependent: :destroy

  validates :name, presence: true
end
