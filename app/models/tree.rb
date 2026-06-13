class Tree < ApplicationRecord
  has_many :tree_memberships, dependent: :destroy
  has_many :users, through: :tree_memberships
  has_many :people, dependent: :destroy
  has_many :families, dependent: :destroy
  has_many :events, dependent: :destroy
  has_many :sources, dependent: :destroy
  has_many :places, dependent: :destroy
  has_many :duplicate_hints, dependent: :destroy

  validates :name, presence: true

  # The род's progenitor: the parentless ancestor with the most descendants — the
  # natural root of the whole-family "родовое древо" (a full descendancy from the
  # founder is the one case where the род stays a clean tree). Ties break to the
  # earliest birth, then id, so the pick is stable. nil for an empty tree.
  #
  # Computed (not stored) so it always tracks the data; cheap at current scale.
  # A manual override and multi-line trees are a future extension — see
  # docs/features/family-tree-view.md.
  def root_person
    return if people.none?

    parentless = people.where.not(
      id: FamilyChild.where(family_id: families.select(:id)).select(:person_id)
    )
    (parentless.presence || people).min_by do |p|
      [ -p.descendant_count, p.birth&.date_start&.year || Float::INFINITY, p.id ]
    end
  end
end
