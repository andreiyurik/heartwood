class Source < ApplicationRecord
  include BelongsToTree, LiveUpdates

  validates :title, presence: true

  has_many :citations, dependent: :destroy
end
