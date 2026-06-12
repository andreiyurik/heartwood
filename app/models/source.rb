class Source < ApplicationRecord
  include BelongsToTree

  validates :title, presence: true

  has_many :citations, dependent: :destroy
end
