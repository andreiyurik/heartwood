# Person (INDI) — one human being; the vertex of the family graph.
# See docs/domain/person.md and docs/domain/domain-model.md.
class Person < ApplicationRecord
  # GEDCOM sex codes: Male, Female, Unknown, Other/Intersex.
  SEXES = %w[M F U X].freeze

  validates :sex, inclusion: { in: SEXES }

  # Families this person formed as a partner, and the families they were a child in.
  has_many :partner_memberships, class_name: "FamilyPartner", dependent: :destroy
  has_many :families_as_partner, through: :partner_memberships, source: :family

  has_many :child_memberships, class_name: "FamilyChild", dependent: :destroy
  has_many :families_as_child, through: :child_memberships, source: :family

  has_many :events, as: :eventable, dependent: :destroy

  # Events that imply the person has died.
  DEATH_KINDS = %w[DEAT BURI CREM].freeze

  # --- Vital events ---

  def birth = events.find_by(kind: "BIRT")
  def death = events.find_by(kind: "DEAT")

  # A person is treated as living until we have evidence of death.
  # (A birth-date age cutoff for privacy is layered on later; see privacy-access.md.)
  def living?
    events.where(kind: DEATH_KINDS).none?
  end

  # --- Derived relationships (computed through Family; see relationship.md) ---

  # Partners of the family this person is a child of.
  def parents
    Person.where(id: FamilyPartner.where(family_id: families_as_child.select(:id)).select(:person_id))
  end

  # Children across every family this person is a partner in.
  def children
    Person.where(id: FamilyChild.where(family_id: families_as_partner.select(:id)).select(:person_id))
  end

  # Other children of the same parents.
  def siblings
    Person.where(id: FamilyChild.where(family_id: families_as_child.select(:id)).select(:person_id))
          .where.not(id: id)
  end

  # Other partners in the families this person is a partner in (spouses/co-parents).
  def partners
    Person.where(id: FamilyPartner.where(family_id: families_as_partner.select(:id)).select(:person_id))
          .where.not(id: id)
  end

  # --- Adding relatives (resolve the right Family so kinship stays derived) ---

  # Add a parent: ensure this person has a birth family, then add the parent as
  # a partner of it.
  def add_parent(attributes)
    family = families_as_child.first || Family.create!.tap { |f| f.children << self }
    Person.create!(attributes).tap { |parent| family.partners << parent }
  end

  # Add a child: ensure this person partners in a family, then add the child to it
  # (so an existing partner becomes the child's second parent).
  def add_child(attributes)
    family = families_as_partner.first || Family.create!.tap { |f| f.partners << self }
    Person.create!(attributes).tap { |child| family.children << child }
  end

  # Add a partner: create a new union between this person and the new partner.
  def add_partner(attributes)
    Person.create!(attributes).tap do |partner|
      Family.create!.partners << [ self, partner ]
    end
  end

  # Full display name composed from its parts (nickname is intentionally excluded).
  # Falls back to "Unknown" when no name parts are present.
  def display_name
    name = [ name_prefix, given_names, surname, name_suffix ].compact_blank.join(" ")
    name.presence || "Unknown"
  end
end
