class Citation < ApplicationRecord
  belongs_to :source
  belongs_to :citable, polymorphic: true

  after_commit :broadcast_refresh_to_tree

  # Gramps' 5-level qualitative confidence scale — richer than GEDCOM's own 4-level
  # QUAY, so we keep it verbatim and collapse to QUAY only on GEDCOM export (not yet
  # built — see docs/domain/source-citation.md).
  enum :confidence, {
    very_low: "very_low", low: "low", normal: "normal", high: "high", very_high: "very_high"
  }, default: "normal"

  def confidence_label
    I18n.t("citations.confidence.#{confidence}")
  end

  private
    # Nothing to refresh once the whole tree has been incinerated.
    def broadcast_refresh_to_tree
      broadcast_refresh_later_to citable.tree if citable&.tree
    end
end
