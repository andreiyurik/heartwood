require "test_helper"

class PersonFormTest < ActiveSupport::TestCase
  setup { @tree = trees(:alpha) }

  test "born and died become the birth and death events" do
    person = @tree.people.create!(given_names: "Ada", surname: "Lovelace", sex: "F", born: "10.12.1815", died: "1852")

    assert_equal Date.new(1815, 12, 10), person.birth.date_start
    assert_equal "1852", person.death.date_label
    assert_equal "1815 – 1852", person.life_years
  end

  test "born and died read back from the events and update them in place" do
    person = @tree.people.create!(given_names: "Ada", sex: "F", born: "1815")
    assert_equal "1815", Person.find(person.id).born

    person.update!(born: "10 December 1815", died: "")
    assert_equal 1, person.events.where(kind: "BIRT").count
    assert_equal Date.new(1815, 12, 10), person.birth.date_start
    assert_nil person.death
  end

  test "clearing a date keeps the event and its place" do
    person = @tree.people.create!(given_names: "Ada", sex: "F", born: "1815")
    person.birth.update!(value: "London")

    person.update!(born: "")
    assert_equal "London", person.birth.value
    assert_nil person.birth.date_raw
  end

  test "the place of birth goes on the birth event, with or without a date" do
    person = @tree.people.create!(given_names: "Praskovya", sex: "F", born: "1885", born_place: "Вятка")
    assert_equal "Вятка", person.birth.place.name
    assert_equal "Вятка", Person.find(person.id).born_place

    only_place = @tree.people.create!(given_names: "Anna", sex: "F", born_place: "Вятка")
    assert_equal [ "Вятка", nil ], [ only_place.birth.place.name, only_place.birth.date_raw ]
    assert_equal 1, @tree.places.where(name: "Вятка").count

    person.update!(born_place: "")
    assert_nil person.birth.reload.place
    assert_equal "1885", person.birth.date_raw
  end

  test "died with the date unknown is a death without a date, so the person is not taken for living" do
    person = @tree.people.create!(given_names: "Praskovya", sex: "F", deceased: "1")
    assert_nil person.death.date_raw
    assert_not person.living?
    assert Person.find(person.id).deceased

    person.update!(deceased: "0")
    assert_nil person.reload.death
    assert person.living?
  end

  test "the tick neither invents a second death nor removes a dated one" do
    person = @tree.people.create!(given_names: "Ada", sex: "F", died: "1852", deceased: "1")
    assert_equal 1, person.events.where(kind: "DEAT").count
    assert_not Person.find(person.id).deceased, "a dated death needs no tick"

    person.update!(died: "1852", deceased: "0")
    assert_equal "1852", person.death.date_raw
  end

  test "the form refuses a nameless person unless the name is marked unknown" do
    person = @tree.people.build(sex: "U", unnamed: "0")
    assert_not person.valid?
    assert_includes person.errors.full_messages.join, I18n.t("activerecord.errors.models.person.attributes.base.unnamed")

    assert @tree.people.build(sex: "U", unnamed: "1").valid?
    assert @tree.people.build(sex: "U").valid?, "imports and restores never pass the flag"
  end

  test "the surname at birth is shown next to the name and found by search" do
    person = @tree.people.create!(given_names: "Olga", surname: "Pavlishcheva", birth_surname: "Pushkina", sex: "F")

    assert_equal I18n.t("people.nee", surname: "Pushkina"), person.birth_surname_label
    assert_includes @tree.people.search("pushkina", user: users(:one)), person
    assert_nil @tree.people.build(surname: "Same", birth_surname: "Same").birth_surname_label
  end

  test "the surname at birth round-trips through GEDCOM" do
    @tree.people.create!(given_names: "Olga", surname: "Pavlishcheva", birth_surname: "Pushkina", sex: "F")
    gedcom = Gedcom::Writer.new(@tree, user: users(:one)).to_gedcom
    assert_match %r{1 NAME Olga /Pushkina/\n2 TYPE BIRTH}i, gedcom

    records = Gedcom::Parser.new(gedcom).parse[:records]
    Gedcom::Mapper.new(records, tree: trees(:beta)).import!
    assert_equal "Pushkina", trees(:beta).people.find_by!(surname: "Pavlishcheva").birth_surname
  end
end
