# A date as genealogists write it: exact, partial, approximate or a range, in GEDCOM or Russian.
# See docs/domain/event.md "Dates".
class FuzzyDate
  MONTHS = %w[JAN FEB MAR APR MAY JUN JUL AUG SEP OCT NOV DEC].freeze

  RUSSIAN_MONTHS = { /\AЯНВ/ => "JAN", /\AФЕВ/ => "FEB", /\AМАР/ => "MAR", /\AАПР/ => "APR",
                     /\AМА[ЙЯ]\z/ => "MAY", /\AИЮН/ => "JUN", /\AИЮЛ/ => "JUL", /\AАВГ/ => "AUG",
                     /\AСЕН/ => "SEP", /\AОКТ/ => "OCT", /\AНОЯ/ => "NOV", /\AДЕК/ => "DEC" }.freeze

  WORDS = {
    "ABT" => %w[ABT ABOUT CIRCA CA C ОК ОКОЛО ПРИБЛ ПРИБЛИЗИТЕЛЬНО ПРИМЕРНО ~],
    "CAL" => %w[CAL], "EST" => %w[EST],
    "BEF" => %w[BEF BEFORE ДО], "AFT" => %w[AFT AFTER ПОСЛЕ],
    "BET" => %w[BET BETWEEN МЕЖДУ], "AND" => %w[AND И],
    "FROM" => %w[FROM С], "TO" => %w[TO ПО]
  }.flat_map { |gedcom, words| words.map { [ it, gedcom ] } }.to_h.freeze

  YEAR_WORDS = %w[Г ГГ ГОД ГОДА].freeze

  # GEDCOM 5.5.1 escapes, GEDCOM 7 keywords, and our own labels "(ст. ст.)" / "(Old Style)".
  JULIAN    = /@#DJULIAN@|\bJULIAN\b|\(?\s*(?:по\s+)?ст\.\s*ст\.?\s*\)?\s*\z|\(?\s*(?:old style|o\.s\.)\s*\)?\s*\z/i
  GREGORIAN = /@#DGREGORIAN@|\bGREGORIAN\b/

  Point = Data.define(:year, :month, :day) do
    def start  = Date.new(year, month || 1, day || 1)
    def finish = day ? start : (month ? start.end_of_month : start.end_of_year)
    def precision = day ? "day" : (month ? "month" : "year")
    def gedcom = [ day, (MONTHS[month - 1] if month), year ].compact.join(" ")

    def label(genitive: false)
      return I18n.l(start, format: "%-d %B %-Y") if day
      return year.to_s unless month

      # An array passed as default: would be read as a list of fallbacks, not as the month names.
      names = (I18n.t("date.standalone_month_names", default: nil) unless genitive) || I18n.t("date.month_names")
      "#{names[month]} #{year}"
    end
  end

  attr_reader :kind, :from, :to

  def self.parse(text)
    text = text.to_s.gsub(GREGORIAN, " ")
    julian = text.match?(JULIAN)
    kind, from, to = structure(tokenize(text.gsub(JULIAN, " ")))
    new(kind, from, to, julian:) if from
  end

  def self.tokenize(text)
    text.to_s.upcase.sub(/\A\s*(\d{3,4})\s*[–—-]\s*(\d{3,4})\s*\z/, 'FROM \\1 TO \\2')
      .gsub(/(\d{1,2})\.(\d{1,2})\.(\d{3,4})/) { "#{$1} #{MONTHS[$2.to_i - 1] || "?"} #{$3}" }
      .split.map { it.delete_suffix(".") }
      .reject { it.in?(YEAR_WORDS) }
      .map { WORDS[it] || english_month(it) || russian_month(it) || it }
  end

  def self.english_month(word)
    MONTHS.find { it == word[0, 3] } if word.match?(/\A[A-Z]{3,}\z/)
  end
  def self.russian_month(word) = RUSSIAN_MONTHS.find { |pattern, _| word.match?(pattern) }&.last

  def self.structure(tokens)
    case tokens
    in [] then nil
    in [ "ABT" | "CAL" | "EST" | "BEF" | "AFT" | "TO" => qualifier, *rest ] then [ qualifier, point(rest) ]
    in [ "BET", *rest ] then range("BET", "AND", rest)
    in [ "FROM", *rest ]
      rest = rest.map { it == "BEF" ? "TO" : it } # "с 1830 до 1840"
      rest.include?("TO") ? range("FROM", "TO", rest) : [ "FROM", point(rest) ]
    else [ "DATE", point(tokens) ]
    end
  end

  def self.range(kind, separator, tokens)
    index = tokens.index(separator) or return
    from, to = point(tokens[0...index]), point(tokens[(index + 1)..])
    [ kind, from, to ] if from && to
  end

  def self.point(tokens)
    case tokens
    in [ /\A\d{3,4}\z/ => year ] then Point.new(year.to_i, nil, nil)
    in [ String => month, /\A\d{3,4}\z/ => year ] if MONTHS.include?(month)
      Point.new(year.to_i, MONTHS.index(month) + 1, nil)
    in [ /\A\d{1,2}\z/ => day, String => month, /\A\d{3,4}\z/ => year ] if MONTHS.include?(month)
      Point.new(year.to_i, MONTHS.index(month) + 1, day.to_i) if Date.valid_date?(year.to_i, MONTHS.index(month) + 1, day.to_i)
    else nil
    end
  end

  private_class_method :tokenize, :english_month, :russian_month, :structure, :range, :point

  def initialize(kind, from, to = nil, julian: false)
    @kind, @from, @to, @julian = kind, from, to, julian
  end

  # Russia changed calendars on 14 February 1918: the day after 31 January (docs/domain/event.md).
  NEW_STYLE_SINCE = Date.new(1918, 2, 14)

  def julian? = @julian
  def old_style_possible? = !julian? && precision == "day" && from.start < NEW_STYLE_SINCE

  def precision
    case kind
    when "DATE" then from.precision
    when "ABT", "CAL", "EST" then "about"
    when "BEF", "TO" then "before"
    when "AFT" then "after"
    when "FROM" then to ? "between" : "after"
    else "between"
    end
  end

  def exact? = kind == "DATE"
  def year = from.year

  # The range is always on the modern calendar, so an Old Style date sorts and compares with the rest.
  def start = modern(calendar_start)
  def finish = modern(calendar_finish)

  def gedcom
    case kind
    when "DATE" then point_gedcom(from)
    when "BET" then "BET #{point_gedcom(from)} AND #{point_gedcom(to)}"
    when "FROM" then [ "FROM #{point_gedcom(from)}", ("TO #{point_gedcom(to)}" if to) ].compact.join(" ")
    else "#{kind} #{point_gedcom(from)}"
    end
  end

  def label
    julian? ? I18n.t("fuzzy_dates.julian", date: calendar_label) : calendar_label
  end

  private
    def calendar_start
      case kind
      when "BEF", "TO" then nil
      when "AFT" then from.finish + 1
      else from.start
      end
    end

    def calendar_finish
      case kind
      when "BEF" then from.start - 1
      when "TO" then from.finish
      when "AFT" then nil
      when "BET" then to.finish
      when "FROM" then to&.finish
      else from.finish
      end
    end

    def point_gedcom(point) = [ ("@#DJULIAN@" if julian?), point.gedcom ].compact.join(" ")

    def modern(date)
      julian? && date ? Date.jd(Date.new(date.year, date.month, date.day, Date::JULIAN).jd) : date
    end

    # Russian puts a month in the genitive after "ок.", "до", "после" and "с".
    def calendar_label
      case kind
      when "DATE" then from.label
      when "BET" then I18n.t("fuzzy_dates.between", from: from.label, to: to.label)
      when "FROM" then to ? I18n.t("fuzzy_dates.from_to", from: from.label(genitive: true), to: to.label) : I18n.t("fuzzy_dates.from", date: from.label(genitive: true))
      when "TO" then I18n.t("fuzzy_dates.to", date: from.label)
      else I18n.t("fuzzy_dates.#{precision}", date: from.label(genitive: true))
      end
    end
end
