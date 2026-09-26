class Person::TreeGraph
  NEIGHBORS = { "ancestors" => :parents, "descendants" => :children }.freeze

  def initialize(person, mode:, depth: 4, ghosts: true, viewer: nil, avatar_url: nil)
    @person     = person
    @mode       = mode
    @depth      = depth
    @ghosts     = ghosts
    @viewer     = viewer
    @avatar_url = avatar_url
  end

  def build
    traverse
    @unions = collect_unions
    ghost_nodes = @ghosts ? collect_ghosts : []

    # Banded couple cards vs circles must match the JS unit grouping, so both derive from unions.
    partnered = @unions.flat_map { |union| union[:partner_ids] }.to_set
    nodes = @persons.values.map do |person|
      node_data(person, generation: @gens[person.id], order: @orders[person.id], partnered: partnered.include?(person.id))
    end
    nodes += ghost_nodes.map { |ghost| ghost.merge(partnered: partnered.include?(ghost[:id])) }

    { nodes:, edges: @edges, unions: @unions, persons: @persons, focus_id: @person.id, mode: @mode }
  end

  private
    def traverse
      @persons    = {}
      @gens       = {}
      @orders     = {}
      @gen_counts = Hash.new(0)
      @edges      = []
      queue       = [ [ @person, 0 ] ]

      while (entry = queue.shift)
        person, gen = entry
        next if @persons.key?(person.id) || gen > @depth

        place(person, gen)

        person.public_send(NEIGHBORS.fetch(@mode)).each do |neighbor|
          @edges << { from_id: person.id, to_id: neighbor.id }
          queue << [ neighbor, gen + 1 ]
        end
      end
    end

    def place(person, gen)
      @persons[person.id] = person
      @gens[person.id]    = gen
      @orders[person.id]  = @gen_counts[gen]
      @gen_counts[gen]   += 1
    end

    # Mutates the traversal maps: descendants mode adds the married-in spouse, whom the BFS never reached.
    def collect_unions
      unions    = []
      seen_fam  = Set.new
      partnered = Set.new

      # Iterate a snapshot: added spouses must not seed unions that drag in unrelated families.
      @persons.values.sort_by { |person| [ @gens[person.id], @orders[person.id] ] }.each do |person|
        family = union_family_for(person)
        next unless family && seen_fam.add?(family.id)

        partners = family.partners.to_a
        add_spouses(partners, person) if @mode == "descendants"

        partner_ids = partners.map(&:id).select { |id| @persons.key?(id) }.first(2)
        next if partner_ids.size < 2
        next if partner_ids.any? { |id| partnered.include?(id) }

        partner_ids.each { |id| partnered << id }
        child_ids = family.children.map(&:id).select { |id| @persons.key?(id) }
        unions << { partner_ids:, child_ids: }
      end

      unions
    end

    # Negative ids keep ghosts apart from real people; only tree members see them.
    def collect_ghosts
      return [] if @depth < 1
      return [] unless @viewer && @person.tree.users.exists?(@viewer.id)

      @ghosts_built = []
      @next_ghost_id = 0

      if @mode == "ancestors"
        @persons.each_value do |person|
          next if @gens[person.id] >= @depth || person.parents.exists?
          ghost_id = add_ghost("parent", person.id, @gens[person.id] + 1)
          @edges << { from_id: person.id, to_id: ghost_id }
        end
      else
        unless @unions.any? { |union| union[:partner_ids].include?(@person.id) }
          ghost_id = add_ghost("partner", @person.id, @gens[@person.id])
          @unions << { partner_ids: [ @person.id, ghost_id ], child_ids: [] }
        end
        ghost_id = add_ghost("child", @person.id, @gens[@person.id] + 1)
        @edges << { from_id: @person.id, to_id: ghost_id }
      end

      @ghosts_built
    end

    def add_ghost(kind, for_id, gen)
      ghost_id = (@next_ghost_id -= 1)
      @ghosts_built << { id: ghost_id, ghost: kind, ghost_for: for_id, generation: gen, order: @gen_counts[gen] }
      @gen_counts[gen] += 1
      ghost_id
    end

    # Remarriages beyond one family are left out of v1.
    def union_family_for(person)
      families = (@mode == "ancestors" ? person.families_as_child : person.families_as_partner).to_a
      return families.first if families.size <= 1

      if @mode == "ancestors"
        families.find { |family| family.partners.count >= 2 } || families.first
      else
        families.find { |family| family.children.any? { |child| @persons.key?(child.id) } } || families.first
      end
    end

    def add_spouses(partners, anchor)
      gen = @gens[anchor.id]
      partners.each { |partner| place(partner, gen) unless @persons.key?(partner.id) }
    end

    def node_data(person, generation:, order:, partnered:)
      base = { id: person.id, generation:, order:, partnered: }
      unless person.visible_to?(@viewer)
        return base.merge(name: I18n.t("people.living"), years: nil, sex: nil, living: true)
      end
      base.merge(name: person.display_name, given: person.given_names, surname: person.surname,
                 years: person.life_years, sex: person.sex, avatar_url: avatar_url_for(person))
    end

    def avatar_url_for(person)
      @avatar_url&.call(person.avatar) if person.avatar.attached?
    end
end
