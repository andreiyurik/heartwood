# Finds likely-duplicate people *within one tree* by scoring every pair on the
# obvious signals. It only suggests — confirming or merging is always the user's
# call (never one-click-accept, the Ancestry anti-pattern). See the smart-hints
# feature. Plain Ruby: no persistence, no callbacks, just scoring.
class DuplicateFinder
  THRESHOLD = 70

  # Weights and the reason key each one contributes when it fires.
  SURNAME_POINTS   = 40
  GIVEN_POINTS     = 30
  BIRTH_POINTS     = 20
  SEX_POINTS       = 10
  BIRTH_YEAR_SLACK = 5

  def initialize(tree)
    @tree = tree
  end

  # [{ person_a:, person_b:, score:, reasons: }] for every pair scoring at or
  # above THRESHOLD. Pairs are ordered by id so a pair has one stable identity.
  def find_all
    people = @tree.people.order(:id).to_a

    people.combination(2).filter_map do |a, b|
      score, reasons = assess(a, b)
      { person_a: a, person_b: b, score:, reasons: } if score >= THRESHOLD
    end
  end

  private

  def assess(a, b)
    score   = 0
    reasons = []

    if surnames_match?(a, b)
      score += SURNAME_POINTS
      reasons << "surname"
    end
    if given_names_match?(a, b)
      score += GIVEN_POINTS
      reasons << "given_names"
    end
    if birth_years_close?(a, b)
      score += BIRTH_POINTS
      reasons << "birth_year"
    end
    if sexes_match?(a, b)
      score += SEX_POINTS
      reasons << "sex"
    end

    [ score, reasons ]
  end

  def surnames_match?(a, b)
    surname = normalize(a.surname)
    surname.present? && surname == normalize(b.surname)
  end

  # Equal, or one a prefix/substring of the other ("Liz" vs "Elizabeth").
  def given_names_match?(a, b)
    ga = normalize(a.given_names)
    gb = normalize(b.given_names)
    return false if ga.blank? || gb.blank?
    ga == gb || ga.include?(gb) || gb.include?(ga)
  end

  def birth_years_close?(a, b)
    ya = a.birth&.date_start&.year
    yb = b.birth&.date_start&.year
    return false unless ya && yb
    (ya - yb).abs <= BIRTH_YEAR_SLACK
  end

  def sexes_match?(a, b)
    a.sex == b.sex && a.sex != "U"
  end

  def normalize(value) = value.to_s.strip.downcase.squeeze(" ")
end
