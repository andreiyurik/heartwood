# Family (FAM) — the structural hub linking partners and their children.
# Kinship is derived *through* Family, never stored as direct person->person edges.
# See docs/domain/family.md and docs/domain/domain-model.md.
class Family < ApplicationRecord
  has_many :partner_memberships, class_name: "FamilyPartner", dependent: :destroy
  has_many :partners, through: :partner_memberships, source: :person

  has_many :child_memberships, class_name: "FamilyChild", dependent: :destroy
  has_many :children, through: :child_memberships, source: :person

  has_many :events, as: :eventable, dependent: :destroy
end
