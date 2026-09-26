module LiveUpdates
  extend ActiveSupport::Concern

  MODELS = %w[Person Event Family FamilyPartner FamilyChild Source Citation].freeze

  included do
    broadcasts_refreshes_to :tree
  end

  # Bulk work would otherwise refresh every open page once per record.
  def self.suppressing(&block)
    MODELS.map(&:constantize).reduce(block) { |inner, model| -> { model.suppressing_turbo_broadcasts(&inner) } }.call
  end
end
