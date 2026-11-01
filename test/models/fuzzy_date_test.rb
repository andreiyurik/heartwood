require "test_helper"

class FuzzyDateTest < ActiveSupport::TestCase
  test "reads the forms people type into GEDCOM, a range and a precision" do
    {
      "14 мая 1781"        => [ "14 MAY 1781", "1781-05-14", "1781-05-14", "day" ],
      "14 МАЙ 1781"        => [ "14 MAY 1781", "1781-05-14", "1781-05-14", "day" ],
      "14.05.1781"         => [ "14 MAY 1781", "1781-05-14", "1781-05-14", "day" ],
      "21 MAR 1685"        => [ "21 MAR 1685", "1685-03-21", "1685-03-21", "day" ],
      "10 декабря 1815 г." => [ "10 DEC 1815", "1815-12-10", "1815-12-10", "day" ],
      "май 1781"           => [ "MAY 1781", "1781-05-01", "1781-05-31", "month" ],
      "Feb 1800"           => [ "FEB 1800", "1800-02-01", "1800-02-28", "month" ],
      "1781"               => [ "1781", "1781-01-01", "1781-12-31", "year" ],
      "1781 г."            => [ "1781", "1781-01-01", "1781-12-31", "year" ],
      "ок. 1696"           => [ "ABT 1696", "1696-01-01", "1696-12-31", "about" ],
      "около 1696"         => [ "ABT 1696", "1696-01-01", "1696-12-31", "about" ],
      "EST 1696"           => [ "EST 1696", "1696-01-01", "1696-12-31", "about" ],
      "до 1900"            => [ "BEF 1900", nil, "1899-12-31", "before" ],
      "после 1900"         => [ "AFT 1900", "1901-01-01", nil, "after" ],
      "между 1830 и 1840"  => [ "BET 1830 AND 1840", "1830-01-01", "1840-12-31", "between" ],
      "1862–1910"          => [ "FROM 1862 TO 1910", "1862-01-01", "1910-12-31", "between" ],
      "1820-1822"          => [ "FROM 1820 TO 1822", "1820-01-01", "1822-12-31", "between" ],
      "с марта 1830 по 1840" => [ "FROM MAR 1830 TO 1840", "1830-03-01", "1840-12-31", "between" ]
    }.each do |typed, (gedcom, start, finish, precision)|
      date = FuzzyDate.parse(typed)
      assert date, "#{typed.inspect} should parse"
      assert_equal [ gedcom, start, finish, precision ],
        [ date.gedcom, date.start&.iso8601, date.finish&.iso8601, date.precision ], typed
    end
  end

  test "text that isn't a date doesn't parse" do
    [ "весна 1812", "", nil, "31 FEB 1800", "13.13.1800", "в войну" ].each do |typed|
      assert_nil FuzzyDate.parse(typed), typed.inspect
    end
  end

  test "labels in the reader's language" do
    I18n.with_locale(:ru) do
      assert_equal "14 мая 1781", FuzzyDate.parse("14 MAY 1781").label
      assert_equal "май 1781", FuzzyDate.parse("MAY 1781").label
      assert_equal "ок. 1696", FuzzyDate.parse("ABT 1696").label
      assert_equal "между 1830 и 1840", FuzzyDate.parse("BET 1830 AND 1840").label
      assert_equal "до 1900", FuzzyDate.parse("BEF 1900").label
    end

    I18n.with_locale(:en) do
      assert_equal "14 May 1781", FuzzyDate.parse("14 мая 1781").label
      assert_equal "abt. 1696", FuzzyDate.parse("ок. 1696").label
      assert_equal "from March 1830 to 1840", FuzzyDate.parse("с марта 1830 по 1840").label
    end
  end
end
