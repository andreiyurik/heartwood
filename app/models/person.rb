class Person < ApplicationRecord
  include BelongsToTree, LiveUpdates, Avatar, Kin, Living, Relatives, Searchable

  SEXES = %w[M F U X].freeze

  has_rich_text :biography
  has_many :events, as: :eventable, dependent: :destroy

  validates :sex, inclusion: { in: SEXES }
  # Every creation path goes through Person.create, so the plan cap lives here.
  validate :tree_has_capacity, on: :create

  def self.named_like(user)
    *given, surname = user.name.split
    given.empty? ? new(given_names: surname) : new(given_names: given.join(" "), surname: surname)
  end

  def birth = events.find_by(kind: "BIRT")
  def death = events.find_by(kind: "DEAT")

  def life_years
    birth_year = event_year(birth)
    death_year = event_year(death)
    return "#{birth_year} – #{death_year}" if birth_year && death_year
    return birth_year.to_s if birth_year
    "† #{death_year}" if death_year
  end

  def more_fields_filled?
    name_prefix.present? || name_suffix.present? || nickname.present? || biography.present?
  end

  # The nickname is left out on purpose.
  def display_name
    name = [ name_prefix, given_names, surname, name_suffix ].compact_blank.join(" ")
    name.presence || I18n.t("people.unknown_name")
  end

  private
    def event_year(event)
      event&.date_start&.year || event&.date_raw.presence
    end

    def tree_has_capacity
      return unless tree&.at_people_limit?
      errors.add(:base, :tree_full, limit: tree.people_limit)
    end
end
