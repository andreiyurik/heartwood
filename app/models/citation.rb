class Citation < ApplicationRecord
  belongs_to :source
  belongs_to :citable, polymorphic: true

  broadcasts_refreshes_to ->(citation) { citation.citable.tree }

  # Gramps' 5-level qualitative confidence scale — richer than GEDCOM's own 4-level
  # QUAY, so we keep it verbatim and collapse to QUAY only on GEDCOM export (not yet
  # built — see docs/domain/source-citation.md).
  enum :confidence, {
    very_low: "very_low", low: "low", normal: "normal", high: "high", very_high: "very_high"
  }, default: "normal"

  def confidence_label
    I18n.t("citations.confidence.#{confidence}")
  end
end
