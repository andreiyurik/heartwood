# Rescans a tree for likely duplicates and refreshes its pending hints. Runs
# after a GEDCOM import and on demand. Pairs a user already dismissed or confirmed
# are left alone, so they don't keep resurfacing. See DuplicateFinder.
class DuplicateScanJob < ApplicationJob
  queue_as :default

  def perform(tree)
    found = DuplicateFinder.new(tree).find_all

    tree.duplicate_hints.pending.delete_all

    found.each do |pair|
      next if resolved?(tree, pair)

      tree.duplicate_hints.create!(
        person_a: pair[:person_a],
        person_b: pair[:person_b],
        score:    pair[:score],
        reasons:  pair[:reasons]
      )
    end

    broadcast_badge(tree)
  end

  private

  def resolved?(tree, pair)
    tree.duplicate_hints
        .where(status: %w[dismissed confirmed])
        .exists?(person_a_id: pair[:person_a].id, person_b_id: pair[:person_b].id)
  end

  def broadcast_badge(tree)
    Turbo::StreamsChannel.broadcast_replace_to(
      tree, :hints,
      target:  "hints-badge",
      partial: "hints/badge",
      locals:  { count: tree.duplicate_hints.pending.count }
    )
  end
end
