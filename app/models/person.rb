# Person (INDI) — one human being; the vertex of the family graph.
# See docs/domain/person.md and docs/domain/domain-model.md.
class Person < ApplicationRecord
  include BelongsToTree

  # GEDCOM sex codes: Male, Female, Unknown, Other/Intersex.
  SEXES = %w[M F U X].freeze

  # Anyone born within this many years of today with no death evidence is "possibly living".
  LIVING_CUTOFF_YEARS = 120

  has_one_attached :avatar

  # Free-prose life story, edited with the Lexxy rich-text editor (Action Text).
  # See docs/architecture/adr/0008-action-text-lexxy.md.
  has_rich_text :biography

  validates :sex, inclusion: { in: SEXES }
  validate :avatar_is_an_image, if: -> { avatar.attached? }
  # The plan cap guards every path that creates people — forms, add-relative,
  # ghost slots, GEDCOM import — because they all go through Person.create.
  validate :tree_has_capacity, on: :create

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

  # Keys for the people#index sort control (see Person.sorted below); order here is
  # display order in the <select>. Whitelisted in the controller before use.
  SORT_OPTIONS = %w[surname_asc surname_desc birth_asc birth_desc created_desc].freeze

  # Sort the list by name, birth date, or when they were added to the tree. Birth-date
  # sorts join each person's BIRT event (there's at most one); people without a recorded
  # birth date sort to the end regardless of direction.
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

  def self.named_like(user)
    *given, surname = user.name.split
    given.empty? ? new(given_names: surname) : new(given_names: given.join(" "), surname: surname)
  end

  # Tree members see everyone; outsiders and guests only see verifiably non-living, non-private people.
  def visible_to?(user)
    return true if user && tree.users.exists?(user.id)
    !living? && !private?
  end

  # Compact lifespan for headers and tree nodes: "1799 – 1837", a lone birth year,
  # or "† 1837" when only the death is known. Nil when no dates are recorded.
  def life_years
    birth_year = event_year(birth)
    death_year = event_year(death)
    return "#{birth_year} – #{death_year}" if birth_year && death_year
    return birth_year.to_s if birth_year
    "† #{death_year}" if death_year
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

  # How many distinct descendants this person has, walking down through children
  # (dedup guards against pedigree collapse / cycles). Used to pick a tree's
  # progenitor — see Tree#root_person.
  def descendant_count
    seen  = Set.new
    queue = children.to_a
    while (person = queue.shift)
      next unless seen.add?(person.id)
      queue.concat(person.children.to_a)
    end
    seen.size
  end

  # --- Relationship calculator (see relationship.md) ---

  # A localized name for how `other` relates to this person ("mother", "second
  # cousin once removed"), or nil when they share no traceable kinship in this
  # tree. Marriage is checked first; otherwise we name the lowest common ancestor.
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

  # Every ancestor reachable by walking up through parents, mapped to how many
  # generations up they are. Includes self at distance 0 so two people who share
  # one as the other's ancestor still find a common entry.
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

    # Derive couples from Family so the view can draw partners as one block.
    # In descendants mode this also pulls in spouses who married into the line.
    unions = collect_unions(persons:, gens:, orders:, gen_counts:, mode:)

    # Dashed "add a relative" slots at the tree's growth frontier. Built before
    # the partnered set so a ghost partner renders as the couple's second card.
    ghost_nodes = ghosts ? collect_ghosts(persons:, gens:, orders:, gen_counts:, unions:, edges:, mode:, depth:) : []

    # Couple members render as banded cards, everyone else as circles — the shape
    # must match the JS unit grouping, so it is derived from the same unions.
    partnered = unions.flat_map { |u| u[:partner_ids] }.to_set
    nodes = persons.values.map do |p|
      node_data(p, generation: gens[p.id], order: orders[p.id], partnered: partnered.include?(p.id))
    end
    nodes += ghost_nodes.map { |g| g.merge(partnered: partnered.include?(g[:id])) }
    { nodes:, edges:, unions:, persons:, focus_id: id, mode: }
  end

  # Couples for the tree view, derived from Family (the source of truth on pairs and
  # children). A union is a single layout block of two partner cards with their
  # children hanging from the middle. Only people present in the current traversal
  # appear; see docs/features/family-tree-view.md for the model and its trade-offs.
  #
  # Mutates the traversal maps: descendants mode adds the married-in spouse (not a
  # blood descendant, so the BFS never reached them) at their partner's generation.
  def collect_unions(persons:, gens:, orders:, gen_counts:, mode:)
    unions    = []
    seen_fam  = Set.new
    partnered = Set.new   # keep each person in at most one couple block

    # Iterate a snapshot — added spouses become nodes but never seed their own union,
    # which would drag in unrelated families through a married-in person.
    persons.values.sort_by { |p| [ gens[p.id], orders[p.id] ] }.each do |person|
      family = union_family_for(person, persons, mode)
      next unless family && seen_fam.add?(family.id)

      partners = family.partners.to_a
      add_spouses(partners, person, persons:, gens:, orders:, gen_counts:) if mode == "descendants"

      partner_ids = partners.map(&:id).select { |pid| persons.key?(pid) }.first(2)
      next if partner_ids.size < 2                                   # single parent → plain node
      next if partner_ids.any? { |pid| partnered.include?(pid) }    # already in another block

      partner_ids.each { |pid| partnered << pid }
      child_ids = family.children.map(&:id).select { |cid| persons.key?(cid) }
      unions << { partner_ids:, child_ids: }
    end

    unions
  end

  # Dashed placeholder nodes that invite adding a missing relative, shown only to
  # members of the tree (viewers can't add anyone). Negative ids keep them apart
  # from real people; the node partial links them to relatives#new.
  #
  # Ancestors mode: an "add parent" slot above every ancestor with no known
  # parents (the research frontier), unless the depth cut them off. Descendants
  # mode: "add partner" / "add child" slots for the focus person only — every
  # other node offers the same actions through its panel without the clutter.
  def collect_ghosts(persons:, gens:, orders:, gen_counts:, unions:, edges:, mode:, depth:)
    return [] if depth < 1   # "just me" view — keep the depth-0 contract literal
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

  # The family that anchors a person's couple block: their parents (ancestors mode)
  # or the marriage that produced the descendants we're showing (descendants mode).
  # Remarriages beyond that one are left out of v1 — see the feature doc.
  def union_family_for(person, persons, mode)
    families = (mode == "ancestors" ? person.families_as_child : person.families_as_partner).to_a
    return families.first if families.size <= 1

    if mode == "ancestors"
      families.find { |f| f.partners.count >= 2 } || families.first
    else
      families.find { |f| f.children.any? { |c| persons.key?(c.id) } } || families.first
    end
  end

  # Add a partner who isn't already in the graph at their spouse's generation, as a
  # leaf (no ancestors of their own on this side). Privacy still applies via node_data.
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

  # The compact year for the lifespan line: the parsed year when the date parsed,
  # otherwise the raw string as typed ("ок. 1696").
  def event_year(event)
    event&.date_start&.year || event&.date_raw.presence
  end

  # Resolve a relative argument into a persisted Person: an existing Person is
  # linked as-is; a hash of attributes builds a new tree-scoped person.
  def resolve_person(relative)
    return relative if relative.is_a?(Person)
    Person.create!(relative.merge(tree: Current.tree))
  end

  # A path to the person's avatar for in-node rendering, or nil when none is
  # attached. Only reached for visible people — redacted nodes never get here,
  # so a living person's photo is never leaked.
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

  # --- Adding relatives (resolve the right Family so kinship stays derived) ---

  # Each method takes either a hash of attributes (build a brand-new person) or
  # an existing Person to link in — see #resolve_person.

  # Add a parent: ensure this person has a birth family, then add the parent as
  # a partner of it.
  def add_parent(relative)
    family = families_as_child.first || Family.create!(tree: Current.tree).tap { |f| f.children << self }
    resolve_person(relative).tap { |parent| family.partners << parent }
  end

  # Add a child: ensure this person partners in a family, then add the child to it
  # (so an existing partner becomes the child's second parent).
  def add_child(relative)
    family = families_as_partner.first || Family.create!(tree: Current.tree).tap { |f| f.partners << self }
    resolve_person(relative).tap { |child| family.children << child }
  end

  # Add a partner: create a new union between this person and the partner.
  def add_partner(relative)
    resolve_person(relative).tap do |partner|
      Family.create!(tree: Current.tree).partners << [ self, partner ]
    end
  end

  # --- Graph traversal for the tree view (see docs/features/family-tree-view.md) ---

  def ancestor_graph(depth: 4, ghosts: true)
    traverse_graph(depth:, neighbors: :parents, mode: "ancestors", ghosts:)
  end

  def descendant_graph(depth: 4, ghosts: true)
    traverse_graph(depth:, neighbors: :children, mode: "descendants", ghosts:)
  end

  # Full display name composed from its parts (nickname is intentionally excluded).
  # Falls back to "Unknown" when no name parts are present.
  def display_name
    name = [ name_prefix, given_names, surname, name_suffix ].compact_blank.join(" ")
    name.presence || I18n.t("people.unknown_name")
  end
end
