class Citation < ApplicationRecord
  belongs_to :source
  belongs_to :citable, polymorphic: true
end
