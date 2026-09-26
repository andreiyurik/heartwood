module BelongsToTree
  extend ActiveSupport::Concern

  included do
    belongs_to :tree, default: -> { Current.tree }
  end
end
