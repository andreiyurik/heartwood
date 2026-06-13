# Person (INDI) — one human being; the vertex of the family graph.
# See docs/domain/person.md and docs/domain/domain-model.md.
class Person < ApplicationRecord
  include BelongsToTree

  # GEDCOM sex codes: Male, Female, Unknown, Other/Intersex.
  SEXES = %w[M F U X].freeze

  # Anyone born within this many years of today with no death evidence is "possibly living".
  LIVING_CUTOFF_YEARS = 120

  has_one_attached :avatar

  validates :sex, inclusion: { in: SEXES }
  validate :avatar_is_an_image, if: -> { avatar.attached? }

  AVATAR_CONTENT_TYPES = %w[image/jpeg image/png image/webp image/gif].freeze
  AVATAR_MAX_BYTES     = 5.megabytes

  # Full-text search across given_names, surname, nickname (LIKE; prefix on each term).
  # Tree-scoped and visibility-scoped: apply after `.visible_to` or chain directly.
  scope :search, ->(query, user: nil) {
    base = visible_to(user)
    terms = query.to_s.strip.split.first(8)
    terms.reduce(base) do |rel, term|
      pattern = "%#{ApplicationRecord.sanitize_sql_like(term)}%"
      rel.where(
        "given_names LIKE :p OR surname LIKE :p OR nickname LIKE :p",
        p: pattern
      )
    end
  }

  # Members of the person's tree see all; others see only verifiably non-living, non-private people.
  scope :visible_to, ->(user) {
    known_dead    = Event.where(eventable_type: "Person", kind: DEATH_KINDS).select(:eventable_id)
    cutoff        = LIVING_CUTOFF_YEARS.years.ago.to_date
    born_long_ago = Event.where(eventable_type: "Person", kind: "BIRT")
                         .where(date_start: ..cutoff).select(:eventable_id)

    publicly_visible = where(private: false, id: known_dead).or(where(private: false, id: born_long_ago))
    next publicly_visible unless user

    where(tree_id: user.tree_memberships.select(:tree_id)).or(publicly_visible)
  }

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

  # Possibly living = no death evidence AND (unknown birth year OR born within LIVING_CUTOFF_YEARS).
  def living?
    return false if events.where(kind: DEATH_KINDS).any?
    birth_year = birth&.date_start&.year
    birth_year.nil? || birth_year > Date.current.year - LIVING_CUTOFF_YEARS
  end

  # Tree members see everyone; outsiders and guests only see verifiably non-living, non-private people.
  def visible_to?(user)
    return true if user && tree.users.exists?(user.id)
    !living? && !private?
  end

  # --- Derived relationships (computed through Family; see relationship.md) ---

  # Partners of the family this person is a child of.
  def parents
    tree.people.where(id: FamilyPartner.where(family_id: families_as_child.select(:id)).select(:person_id))
  end

  # Children across every family this person is a partner in.
  def children
    tree.people.where(id: FamilyChild.where(family_id: families_as_partner.select(:id)).select(:person_id))
  end

  # Other children of the same parents.
  def siblings
    tree.people.where(id: FamilyChild.where(family_id: families_as_child.select(:id)).select(:person_id))
               .where.not(id: id)
  end

  # Other partners in the families this person is a partner in (spouses/co-parents).
  def partners
    tree.people.where(id: FamilyPartner.where(family_id: families_as_partner.select(:id)).select(:person_id))
               .where.not(id: id)
  end

  private

  def traverse_graph(depth:, neighbors:, mode:)
    persons    = {}
    gens       = {}
    orders     = {}
    gen_counts = Hash.new(0)
    edges      = []
    queue      = [[self, 0]]

    while (entry = queue.shift)
      person, gen = entry
      next if persons.key?(person.id) || gen > depth

      persons[person.id] = person
      gens[person.id]    = gen
      orders[person.id]  = gen_counts[gen]
      gen_counts[gen]   += 1

      person.public_send(neighbors).each do |neighbor|
        edges << { from_id: person.id, to_id: neighbor.id }
        queue << [neighbor, gen + 1]
      end
    end

    nodes = persons.values.map { |p| node_data(p, generation: gens[p.id], order: orders[p.id]) }
    { nodes:, edges:, persons:, focus_id: id, mode: }
  end

  def node_data(person, generation:, order:)
    base = { id: person.id, generation:, order: }
    unless person.visible_to?(Current.user)
      return base.merge(name: I18n.t("people.living"), birth_year: nil, sex: nil, living: true)
    end
    base.merge(name: person.display_name, birth_year: person.birth&.date_raw,
               sex: person.sex, avatar_url: avatar_url_for(person))
  end

  # A path to the person's avatar for in-node rendering, or nil when none is
  # attached. Only reached for visible people — redacted nodes never get here,
  # so a living person's photo is never leaked.
  def avatar_url_for(person)
    return unless person.avatar.attached?
    Rails.application.routes.url_helpers.rails_blob_path(person.avatar, only_path: true)
  end

  def avatar_is_an_image
    unless avatar.content_type.in?(AVATAR_CONTENT_TYPES)
      errors.add(:avatar, :invalid_content_type)
    end
    if avatar.byte_size > AVATAR_MAX_BYTES
      errors.add(:avatar, :too_large)
    end
  end

  public

  # --- Adding relatives (resolve the right Family so kinship stays derived) ---

  # Add a parent: ensure this person has a birth family, then add the parent as
  # a partner of it.
  def add_parent(attributes)
    family = families_as_child.first || Family.create!(tree: Current.tree).tap { |f| f.children << self }
    Person.create!(attributes.merge(tree: Current.tree)).tap { |parent| family.partners << parent }
  end

  # Add a child: ensure this person partners in a family, then add the child to it
  # (so an existing partner becomes the child's second parent).
  def add_child(attributes)
    family = families_as_partner.first || Family.create!(tree: Current.tree).tap { |f| f.partners << self }
    Person.create!(attributes.merge(tree: Current.tree)).tap { |child| family.children << child }
  end

  # Add a partner: create a new union between this person and the new partner.
  def add_partner(attributes)
    Person.create!(attributes.merge(tree: Current.tree)).tap do |partner|
      Family.create!(tree: Current.tree).partners << [ self, partner ]
    end
  end

  # --- Graph traversal for the tree view (see docs/features/family-tree-view.md) ---

  def ancestor_graph(depth: 4)
    traverse_graph(depth:, neighbors: :parents, mode: "ancestors")
  end

  def descendant_graph(depth: 4)
    traverse_graph(depth:, neighbors: :children, mode: "descendants")
  end

  # Full display name composed from its parts (nickname is intentionally excluded).
  # Falls back to "Unknown" when no name parts are present.
  def display_name
    name = [ name_prefix, given_names, surname, name_suffix ].compact_blank.join(" ")
    name.presence || I18n.t("people.unknown_name")
  end
end
