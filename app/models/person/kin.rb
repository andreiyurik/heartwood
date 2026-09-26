module Person::Kin
  extend ActiveSupport::Concern

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
end
