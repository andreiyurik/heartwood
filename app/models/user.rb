class User < ApplicationRecord
  has_secure_password
  has_many :sessions, dependent: :destroy
  has_many :tree_memberships, dependent: :destroy
  has_many :trees, through: :tree_memberships

  normalizes :email_address, with: ->(e) { e.strip.downcase }
end
