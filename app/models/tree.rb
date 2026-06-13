class Tree < ApplicationRecord
  has_many :tree_memberships, dependent: :destroy
  has_many :users, through: :tree_memberships
  has_many :people, dependent: :destroy
  has_many :families, dependent: :destroy
  has_many :events, dependent: :destroy
  has_many :sources, dependent: :destroy
  has_many :places, dependent: :destroy
  has_many :duplicate_hints, dependent: :destroy

  validates :name, presence: true
end
