module BelongsToTree
  extend ActiveSupport::Concern

  included do
    belongs_to :tree
  end
end
