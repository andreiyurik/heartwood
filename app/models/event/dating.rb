module Event::Dating
  extend ActiveSupport::Concern

  GEDCOM_DATE = /\A[A-Z0-9 @#\/().,:-]+\z/

  included do
    before_save :assign_date_range, if: :date_raw_changed?
  end

  def fuzzy_date
    FuzzyDate.parse(date_raw)
  end

  def date_label
    fuzzy_date&.label || date_raw
  end

  # A year for "1781 – 1837"; a fuzzy date keeps its qualifier ("ок. 1696").
  def life_year
    date = fuzzy_date
    date&.exact? ? date.year : date_label.presence
  end

  # Unparsed text that already looks like GEDCOM (a Julian date, an INT phrase) passes through untouched.
  def gedcom_date
    return if date_raw.blank?
    fuzzy_date&.gedcom || (date_raw.match?(GEDCOM_DATE) ? date_raw : "(#{date_raw.delete("()")})")
  end

  private
    def assign_date_range
      date = fuzzy_date
      self.date_start, self.date_end, self.date_precision = date&.start, date&.finish, date&.precision
    end
end
