class User < ApplicationRecord
  has_secure_password
  has_many :sessions, dependent: :destroy
  has_many :tree_memberships, dependent: :destroy
  has_many :trees, through: :tree_memberships

  normalizes :email_address, with: ->(e) { e.strip.downcase }

  validates :name, presence: true, length: { maximum: 240 }
  validates :email_address, presence: true, uniqueness: true,
            format: { with: URI::MailTo::EMAIL_REGEXP }
  # Minimum strength on new/changed passwords; skipped for records loaded without one.
  validates :password, length: { minimum: 8 }, allow_nil: true
end
