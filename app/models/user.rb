class User < ApplicationRecord
  include PrivacyConsent

  has_secure_password
  has_many :sessions, dependent: :destroy
  has_many :tree_memberships, dependent: :destroy
  has_many :trees, through: :tree_memberships
  has_many :imports, dependent: :destroy
  has_many :archives, dependent: :destroy
  has_many :edits, dependent: :nullify
  has_many :questions, foreign_key: :asker_id, dependent: :nullify
  has_many :closed_questions, class_name: "Question", foreign_key: :closed_by_id, dependent: :nullify
  has_many :answers, dependent: :nullify
  has_many :comments, dependent: :nullify
  has_many :reverted_edits, class_name: "Edit", foreign_key: :reverted_by_id, dependent: :nullify

  before_destroy(prepend: true) { owned_trees.each(&:incinerate_later) }

  generates_token_for :digest_unsubscribe

  before_create { self.locale ||= I18n.locale }

  normalizes :email_address, with: ->(e) { e.strip.downcase }

  validates :name, presence: true, length: { maximum: 240 }
  validates :email_address, presence: true, uniqueness: true,
            format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :password, length: { minimum: 8 }, allow_nil: true

  def owned_trees
    trees.where(tree_memberships: { role: "owner" })
  end

  def self.sign_up!(attributes, tree_name: nil, join: nil)
    transaction do
      new(attributes).tap { it.save!(context: :sign_up) }.tap do |user|
        if join
          user.tree_memberships.create!(tree: join, role: "editor")
        else
          user.tree_memberships.create!(tree: Tree.create!(name: tree_name.presence || I18n.t("trees.default_name")), role: "owner")
        end
      end
    end
  end
end
