module Person::Searchable
  extend ActiveSupport::Concern

  SORT_OPTIONS = %w[surname_asc surname_desc birth_asc birth_desc created_desc].freeze

  included do
    scope :search, ->(query, user: nil) {
      terms = query.to_s.strip.split.first(8)
      terms.reduce(visible_to(user)) do |relation, term|
        pattern = "%#{ApplicationRecord.sanitize_sql_like(term)}%"
        relation.where("given_names LIKE :p OR surname LIKE :p OR nickname LIKE :p", p: pattern)
      end
    }

    # People without a birth date sort last in both directions.
    scope :sorted, ->(key) {
      case key.to_s
      when "surname_desc"
        reorder(surname: :desc, given_names: :desc)
      when "birth_asc", "birth_desc"
        direction = key.to_s == "birth_asc" ? "ASC" : "DESC"
        joins("LEFT JOIN events birth_evt ON birth_evt.eventable_id = people.id " \
              "AND birth_evt.eventable_type = 'Person' AND birth_evt.kind = 'BIRT'")
          .reorder(Arel.sql("birth_evt.date_start IS NULL, birth_evt.date_start #{direction}"))
      when "created_desc"
        reorder(created_at: :desc)
      else
        reorder(surname: :asc, given_names: :asc)
      end
    }
  end
end
