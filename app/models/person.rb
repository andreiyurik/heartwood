class Person < ApplicationRecord
  include BelongsToTree

  SEXES = %w[M F U X].freeze

  LIVING_CUTOFF_YEARS = 120

  has_one_attached :avatar

  has_rich_text :biography

  validates :sex, inclusion: { in: SEXES }
  validate :avatar_is_an_image, if: -> { avatar.attached? }
  # Every creation path goes through Person.create, so the plan cap lives here.
  validate :tree_has_capacity, on: :create

  AVATAR_CONTENT_TYPES = %w[image/jpeg image/png image/webp image/gif].freeze
  AVATAR_MAX_BYTES     = 5.megabytes

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

  SORT_OPTIONS = %w[surname_asc surname_desc birth_asc birth_desc created_desc].freeze

  # People without a birth date sort last in both directions.
  scope :sorted, ->(key) {
    case key.to_s
    when "surname_desc"
      reorder(surname: :desc, given_names: :desc)
    when "birth_asc", "birth_desc"
      direction = key.to_s == "birth_asc" ? "ASC" : "DESC"
      joins("LEFT JOIN events birth_evt ON birth_evt.eventable_id = people.id " \
            "AND birth_evt.eventable_type = 'Person' AND birth_evt.kind = 'BIRT'")
        .reorder(Arel.sql("birth_evt.date_start IS NULL, birth_evt.date_start #{direction}"))
    when "created_desc"
      reorder(created_at: :desc)
    else
      reorder(surname: :asc, given_names: :asc)
    end
  }

  scope :visible_to, ->(user) {
    known_dead    = Event.where(eventable_type: "Person", kind: DEATH_KINDS).select(:eventable_id)
    cutoff        = LIVING_CUTOFF_YEARS.years.ago.to_date
    born_long_ago = Event.where(eventable_type: "Person", kind: "BIRT")
                         .where(date_start: ..cutoff).select(:eventable_id)

    publicly_visible = where(private: false, id: known_dead).or(where(private: false, id: born_long_ago))
    next publicly_visible unless user

    where(tree_id: user.tree_memberships.select(:tree_id)).or(publicly_visible)
  }

  has_many :partner_memberships, class_name: "FamilyPartner", dependent: :destroy
  has_many :families_as_partner, through: :partner_memberships, source: :family

  has_many :child_memberships, class_name: "FamilyChild", dependent: :destroy
  has_many :families_as_child, through: :child_memberships, source: :family

  has_many :events, as: :eventable, dependent: :destroy

  DEATH_KINDS = %w[DEAT BURI CREM].freeze

  def birth = events.find_by(kind: "BIRT")
  def death = events.find_by(kind: "DEAT")

  def living?
    return false if events.where(kind: DEATH_KINDS).any?
    birth_year = birth&.date_start&.year
    birth_year.nil? || birth_year > Date.current.year - LIVING_CUTOFF_YEARS
  end

  def more_fields_filled?
    name_prefix.present? || name_suffix.present? || nickname.present? || biography.present?
  end

  def self.named_like(user)
    *given, surname = user.name.split
    given.empty? ? new(given_names: surname) : new(given_names: given.join(" "), surname: surname)
  end

  def visible_to?(user)
    return true if user && tree.users.exists?(user.id)
    !living? && !private?
  end

  def life_years
    birth_year = event_year(birth)
    death_year = event_year(death)
    return "#{birth_year} – #{death_year}" if birth_year && death_year
    return birth_year.to_s if birth_year
    "† #{death_year}" if death_year
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

  def relationship_to(other)
    return nil unless other.is_a?(Person) && other.tree_id == tree_id && other.id != id

    return Kinship.spouse(other.sex) if partners.exists?(other.id)

    mine   = ancestor_distances
    theirs = other.ancestor_distances
    shared = mine.keys & theirs.keys
    return nil if shared.empty?

    lca = shared.min_by { |id| mine[id] + theirs[id] }
    Kinship.new(up: mine[lca], down: theirs[lca], sex: other.sex).to_s
  end

  # Includes self at distance 0 so a shared ancestor can be the other person.
  def ancestor_distances
    distances = { id => 0 }
    queue     = [ self ]

    while (person = queue.shift)
      person.parents.each do |parent|
        next if distances.key?(parent.id)
        distances[parent.id] = distances[person.id] + 1
        queue << parent
      end
    end

    distances
  end

  private

  def traverse_graph(depth:, neighbors:, mode:, ghosts: true)
    persons    = {}
    gens       = {}
    orders     = {}
    gen_counts = Hash.new(0)
    edges      = []
    queue      = [ [ self, 0 ] ]

    while (entry = queue.shift)
      person, gen = entry
      next if persons.key?(person.id) || gen > depth

      persons[person.id] = person
      gens[person.id]    = gen
      orders[person.id]  = gen_counts[gen]
      gen_counts[gen]   += 1

      person.public_send(neighbors).each do |neighbor|
        edges << { from_id: person.id, to_id: neighbor.id }
        queue << [ neighbor, gen + 1 ]
      end
    end

    unions = collect_unions(persons:, gens:, orders:, gen_counts:, mode:)

    ghost_nodes = ghosts ? collect_ghosts(persons:, gens:, orders:, gen_counts:, unions:, edges:, mode:, depth:) : []

    # Banded couple cards vs circles must match the JS unit grouping, so both derive from unions.
    partnered = unions.flat_map { |u| u[:partner_ids] }.to_set
    nodes = persons.values.map do |p|
      node_data(p, generation: gens[p.id], order: orders[p.id], partnered: partnered.include?(p.id))
    end
    nodes += ghost_nodes.map { |g| g.merge(partnered: partnered.include?(g[:id])) }
    { nodes:, edges:, unions:, persons:, focus_id: id, mode: }
  end

  # Mutates the traversal maps: descendants mode adds the married-in spouse, whom the BFS never reached.
  def collect_unions(persons:, gens:, orders:, gen_counts:, mode:)
    unions    = []
    seen_fam  = Set.new
    partnered = Set.new

    # Iterate a snapshot: added spouses must not seed unions that drag in unrelated families.
    persons.values.sort_by { |p| [ gens[p.id], orders[p.id] ] }.each do |person|
      family = union_family_for(person, persons, mode)
      next unless family && seen_fam.add?(family.id)

      partners = family.partners.to_a
      add_spouses(partners, person, persons:, gens:, orders:, gen_counts:) if mode == "descendants"

      partner_ids = partners.map(&:id).select { |pid| persons.key?(pid) }.first(2)
      next if partner_ids.size < 2
      next if partner_ids.any? { |pid| partnered.include?(pid) }

      partner_ids.each { |pid| partnered << pid }
      child_ids = family.children.map(&:id).select { |cid| persons.key?(cid) }
      unions << { partner_ids:, child_ids: }
    end

    unions
  end

  # Negative ids keep ghosts apart from real people; only tree members see them.
  def collect_ghosts(persons:, gens:, orders:, gen_counts:, unions:, edges:, mode:, depth:)
    return [] if depth < 1
    return [] unless Current.user && tree.users.exists?(Current.user.id)

    ghosts  = []
    next_id = 0
    add = lambda do |kind, for_id, gen|
      gid = (next_id -= 1)
      ghosts << { id: gid, ghost: kind, ghost_for: for_id,
                  generation: gen, order: gen_counts[gen] }
      gen_counts[gen] += 1
      gid
    end

    if mode == "ancestors"
      persons.each_value do |p|
        next if gens[p.id] >= depth || p.parents.exists?
        gid = add.call("parent", p.id, gens[p.id] + 1)
        edges << { from_id: p.id, to_id: gid }
      end
    else
      unless unions.any? { |u| u[:partner_ids].include?(id) }
        gid = add.call("partner", id, gens[id])
        unions << { partner_ids: [ id, gid ], child_ids: [] }
      end
      gid = add.call("child", id, gens[id] + 1)
      edges << { from_id: id, to_id: gid }
    end

    ghosts
  end

  # Remarriages beyond one family are left out of v1.
  def union_family_for(person, persons, mode)
    families = (mode == "ancestors" ? person.families_as_child : person.families_as_partner).to_a
    return families.first if families.size <= 1

    if mode == "ancestors"
      families.find { |f| f.partners.count >= 2 } || families.first
    else
      families.find { |f| f.children.any? { |c| persons.key?(c.id) } } || families.first
    end
  end

  def add_spouses(partners, anchor, persons:, gens:, orders:, gen_counts:)
    gen = gens[anchor.id]
    partners.each do |partner|
      next if persons.key?(partner.id)
      persons[partner.id] = partner
      gens[partner.id]    = gen
      orders[partner.id]  = gen_counts[gen]
      gen_counts[gen]    += 1
    end
  end

  def node_data(person, generation:, order:, partnered: false)
    base = { id: person.id, generation:, order:, partnered: }
    unless person.visible_to?(Current.user)
      return base.merge(name: I18n.t("people.living"), years: nil, sex: nil, living: true)
    end
    base.merge(name: person.display_name, given: person.given_names, surname: person.surname,
               years: person.life_years,
               sex: person.sex, avatar_url: avatar_url_for(person))
  end

  def event_year(event)
    event&.date_start&.year || event&.date_raw.presence
  end

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
    Person.create!(relative.merge(tree: Current.tree))
  end

  # Only reached for visible people, so a living person's photo never leaks.
  def avatar_url_for(person)
    return unless person.avatar.attached?
    Rails.application.routes.url_helpers.rails_blob_path(person.avatar, only_path: true)
  end

  def tree_has_capacity
    return unless tree&.at_people_limit?
    errors.add(:base, :tree_full, limit: tree.people_limit)
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

  def relative_candidates(query, user:, relation: nil)
    return Person.none if query.to_s.strip.blank?

    tree.people.search(query, user: user)
        .where.not(id: [ id, *people_in(relation).map(&:id) ])
        .order(:surname, :given_names)
        .limit(8)
  end

  def add_parent(relative)
    family = families_as_child.first || Family.create!(tree: Current.tree).tap { |f| f.children << self }
    resolve_person(relative).tap { |parent| family.partners << parent }
  end

  def add_child(relative)
    family = families_as_partner.first || Family.create!(tree: Current.tree).tap { |f| f.partners << self }
    resolve_person(relative).tap { |child| family.children << child }
  end

  def add_partner(relative)
    resolve_person(relative).tap do |partner|
      Family.create!(tree: Current.tree).partners << [ self, partner ]
    end
  end

  def ancestor_graph(depth: 4, ghosts: true)
    traverse_graph(depth:, neighbors: :parents, mode: "ancestors", ghosts:)
  end

  def descendant_graph(depth: 4, ghosts: true)
    traverse_graph(depth:, neighbors: :children, mode: "descendants", ghosts:)
  end

  # The nickname is left out on purpose.
  def display_name
    name = [ name_prefix, given_names, surname, name_suffix ].compact_blank.join(" ")
    name.presence || I18n.t("people.unknown_name")
  end
end
