module Person::Living
  extend ActiveSupport::Concern

  LIVING_CUTOFF_YEARS = 120
  DEATH_KINDS = %w[DEAT BURI CREM].freeze

  included do
    scope :visible_to, ->(user) {
      known_dead    = Event.where(eventable_type: "Person", kind: DEATH_KINDS).select(:eventable_id)
      cutoff        = LIVING_CUTOFF_YEARS.years.ago.to_date
      born_long_ago = Event.where(eventable_type: "Person", kind: "BIRT")
                           .where(date_start: ..cutoff).select(:eventable_id)

      publicly_visible = where(private: false, id: known_dead).or(where(private: false, id: born_long_ago))
      next publicly_visible unless user

      where(tree_id: user.tree_memberships.select(:tree_id)).or(publicly_visible)
    }
  end

  def living?
    return false if events.where(kind: DEATH_KINDS).any?
    birth_year = birth&.date_start&.year
    birth_year.nil? || birth_year > Date.current.year - LIVING_CUTOFF_YEARS
  end

  def visible_to?(user)
    return true if user && tree.users.exists?(user.id)
    !living? && !private?
  end
end
