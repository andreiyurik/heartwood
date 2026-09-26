class Tree < ApplicationRecord
  # An expired family plan behaves as free only for adding people; existing data is never locked.
  PLANS = {
    "free"   => { people_limit: 100 },
    "family" => { people_limit: nil }
  }.freeze

  has_many :tree_memberships, dependent: :destroy
  has_many :users, through: :tree_memberships
  has_many :people, dependent: :destroy
  has_many :families, dependent: :destroy
  has_many :events, dependent: :destroy
  has_many :sources, dependent: :destroy
  has_many :places, dependent: :destroy
  has_many :duplicate_hints, dependent: :destroy
  has_many :imports, dependent: :destroy

  validates :name, presence: true
  validates :plan, inclusion: { in: PLANS.keys }
  validates :join_code, presence: true, uniqueness: true

  before_validation { self.join_code ||= generate_join_code }

  def reset_join_code!
    update! join_code: generate_join_code
  end

  def effective_plan
    plan == "family" && (plan_expires_at.nil? || plan_expires_at.future?) ? "family" : "free"
  end

  def family_plan? = effective_plan == "family"

  def people_limit = PLANS.fetch(effective_plan)[:people_limit]

  def people_remaining
    people_limit && [ people_limit - people.count, 0 ].max
  end

  def at_people_limit?
    people_limit ? people.count >= people_limit : false
  end

  def activate_family!(period: 1.year)
    base = [ plan_expires_at, Time.current ].compact.max
    update!(plan: "family", plan_expires_at: base + period)
  end

  # Ties break to the earliest birth, then id, so the pick is stable.
  def root_person
    return if people.none?

    parentless = people.where.not(
      id: FamilyChild.where(family_id: families.select(:id)).select(:person_id)
    )
    (parentless.presence || people).min_by do |p|
      [ -p.descendant_count, p.birth&.date_start&.year || Float::INFINITY, p.id ]
    end
  end

  private
    def generate_join_code
      SecureRandom.alphanumeric(12).scan(/.{4}/).join("-")
    end
end
