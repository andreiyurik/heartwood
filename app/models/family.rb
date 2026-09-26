class Family < ApplicationRecord
  include BelongsToTree

  has_many :partner_memberships, class_name: "FamilyPartner", dependent: :destroy
  has_many :partners, through: :partner_memberships, source: :person

  has_many :child_memberships, class_name: "FamilyChild", dependent: :destroy
  has_many :children, through: :child_memberships, source: :person

  has_many :events, as: :eventable, dependent: :destroy
end
