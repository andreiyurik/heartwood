# Join model: a person participating in a Family as a partner.
# See docs/domain/family.md.
class FamilyPartner < ApplicationRecord
  belongs_to :family
  belongs_to :person
end
