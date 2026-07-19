require "test_helper"

# DuplicateFinder scores every pair of people in a tree and surfaces the likely
# matches. It only suggests — see the smart-hints feature.
class DuplicateFinderTest < ActiveSupport::TestCase
  setup { Current.tree = trees(:alpha) }
  teardown { Current.reset }

  def person(attrs)
    Person.create!({ tree: Current.tree, sex: "U" }.merge(attrs))
  end

  def born(record, year)
    record.events.create!(kind: "BIRT", date_raw: year.to_s, date_start: Date.new(year, 1, 1))
    record
  end

  test "flags an obvious duplicate with all four reasons" do
    a = born(person(given_names: "John", surname: "Smith", sex: "M"), 1900)
    b = born(person(given_names: "John", surname: "Smith", sex: "M"), 1902)

    results = DuplicateFinder.new(Current.tree).find_all
    assert_equal 1, results.size

    pair = results.first
    assert_equal [ a, b ].to_set, [ pair[:person_a], pair[:person_b] ].to_set
    assert_operator pair[:score], :>=, DuplicateFinder::THRESHOLD
    assert_equal %w[surname given_names birth_year sex].to_set, pair[:reasons].to_set
  end

  test "surname and given names together reach the threshold" do
    person(given_names: "John", surname: "Smith")
    person(given_names: "John", surname: "Smith")
    assert_equal 1, DuplicateFinder.new(Current.tree).find_all.size
  end

  test "a shared surname alone stays below the threshold" do
    person(given_names: "John",   surname: "Smith", sex: "M")
    person(given_names: "Robert", surname: "Smith", sex: "F")
    assert_empty DuplicateFinder.new(Current.tree).find_all
  end

  test "clearly different people are not flagged" do
    person(given_names: "John",  surname: "Smith",  sex: "M")
    person(given_names: "Maria", surname: "Garcia", sex: "F")
    assert_empty DuplicateFinder.new(Current.tree).find_all
  end

  test "nicknames and full names count as a given-name match" do
    person(given_names: "Liz",       surname: "Taylor", sex: "F")
    person(given_names: "Lizabeth",  surname: "Taylor", sex: "F")
    assert_equal 1, DuplicateFinder.new(Current.tree).find_all.size
  end

  test "scanning is scoped to its own tree" do
    born(person(given_names: "John", surname: "Smith", sex: "M"), 1900)
    born(person(given_names: "John", surname: "Smith", sex: "M"), 1900)
    Person.create!(given_names: "John", surname: "Smith", sex: "M", tree: trees(:beta))
    assert_equal 1, DuplicateFinder.new(Current.tree).find_all.size
  end
end
