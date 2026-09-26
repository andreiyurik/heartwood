class User < ApplicationRecord
  has_secure_password
  has_many :sessions, dependent: :destroy
  has_many :tree_memberships, dependent: :destroy
  has_many :trees, through: :tree_memberships
  has_many :imports, dependent: :destroy

  normalizes :email_address, with: ->(e) { e.strip.downcase }

  validates :name, presence: true, length: { maximum: 240 }
  validates :email_address, presence: true, uniqueness: true,
            format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :password, length: { minimum: 8 }, allow_nil: true

  def self.sign_up!(attributes, tree_name: nil, join: nil)
    transaction do
      create!(attributes).tap do |user|
        if join
          user.tree_memberships.create!(tree: join, role: "editor")
        else
          user.tree_memberships.create!(tree: Tree.create!(name: tree_name.presence || I18n.t("trees.default_name")), role: "owner")
        end
      end
    end
  end
end
