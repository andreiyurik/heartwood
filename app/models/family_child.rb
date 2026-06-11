# Join model: a person who is a child in a Family.
# `pedigree` carries the GEDCOM child-to-family relationship (birth/adopted/foster).
# See docs/domain/family.md.
class FamilyChild < ApplicationRecord
  belongs_to :family
  belongs_to :person
  belongs_to :tree

  before_validation :inherit_tree_from_family

  private

  def inherit_tree_from_family
    self.tree ||= family&.tree
  end
end
