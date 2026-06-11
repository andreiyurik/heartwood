# Join model: a person participating in a Family as a partner.
# See docs/domain/family.md.
class FamilyPartner < ApplicationRecord
  belongs_to :family
  belongs_to :person
  belongs_to :tree

  before_validation :inherit_tree_from_family

  private

  def inherit_tree_from_family
    self.tree ||= family&.tree
  end
end
