module Person::Relatives
  extend ActiveSupport::Concern

  included do
    has_many :partner_memberships, class_name: "FamilyPartner", dependent: :destroy
    has_many :families_as_partner, through: :partner_memberships, source: :family

    has_many :child_memberships, class_name: "FamilyChild", dependent: :destroy
    has_many :families_as_child, through: :child_memberships, source: :family
  end

  def parents
    tree.people.where(id: FamilyPartner.where(family_id: families_as_child.select(:id)).select(:person_id))
  end

  def children
    tree.people.where(id: FamilyChild.where(family_id: families_as_partner.select(:id)).select(:person_id))
  end

  def siblings
    tree.people.where(id: FamilyChild.where(family_id: families_as_child.select(:id)).select(:person_id))
               .where.not(id: id)
  end

  def partners
    tree.people.where(id: FamilyPartner.where(family_id: families_as_partner.select(:id)).select(:person_id))
               .where.not(id: id)
  end

  # The seen set guards against pedigree collapse and cycles.
  def descendant_count
    seen  = Set.new
    queue = children.to_a
    while (person = queue.shift)
      next unless seen.add?(person.id)
      queue.concat(person.children.to_a)
    end
    seen.size
  end

  def relative_candidates(query, user:, relation: nil)
    return Person.none if query.to_s.strip.blank?

    tree.people.search(query, user: user)
        .where.not(id: [ id, *people_in(relation).map(&:id) ])
        .order(:surname, :given_names)
        .limit(8)
  end

  def add_parent(relative)
    family = families_as_child.first || Family.create!(tree: tree).tap { |f| f.children << self }
    resolve_person(relative).tap { |parent| family.partners << parent }
  end

  def add_child(relative)
    family = families_as_partner.first || Family.create!(tree: tree).tap { |f| f.partners << self }
    resolve_person(relative).tap { |child| family.children << child }
  end

  def add_partner(relative)
    resolve_person(relative).tap do |partner|
      Family.create!(tree: tree).partners << [ self, partner ]
    end
  end

  private
    def people_in(relation)
      case relation
      when "parent"  then parents
      when "child"   then children
      when "partner" then partners
      else []
      end
    end

    def resolve_person(relative)
      return relative if relative.is_a?(Person)
      Person.create!(relative.merge(tree: tree))
    end
end
