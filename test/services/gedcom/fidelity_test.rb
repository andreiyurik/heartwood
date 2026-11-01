require "test_helper"

# Everything a user can type must survive export → re-import (docs/interop/gedcom.md "What we write and read").
class Gedcom::FidelityTest < ActiveSupport::TestCase
  setup do
    @user   = users(:one)
    @tree   = shared_tree("Origin")
    @target = shared_tree("Reimport")
  end

  test "name parts survive the round-trip" do
    person(name_prefix: "Dr.", given_names: "Johann Sebastian", nickname: "Basti", surname: "Bach", name_suffix: "Sr.")

    ged = export
    assert_match(/1 NAME Johann Sebastian \/Bach\/\n2 NPFX Dr\.\n2 GIVN Johann Sebastian\n2 NICK Basti\n2 SURN Bach\n2 NSFX Sr\./, ged)

    back = reimport(ged).people.sole
    assert_equal [ "Dr.", "Johann Sebastian", "Basti", "Bach", "Sr." ],
      back.values_at(:name_prefix, :given_names, :nickname, :surname, :name_suffix)
  end

  test "the biography survives as a note, line by line" do
    person(given_names: "Anna", biography: "<div>Born in Eisenach.</div><div>Moved to Leipzig.</div>")

    ged = export
    assert_match(/1 NOTE Born in Eisenach\.\n2 CONT Moved to Leipzig\./, ged)

    assert_equal "Born in Eisenach.\nMoved to Leipzig.", reimport(ged).people.sole.biography.to_plain_text
  end

  test "sources and citations survive with page, confidence, text and date" do
    birth = person(given_names: "Anna").events.create!(kind: "BIRT", date_raw: "1685")
    birth.cite({ title: "Eisenach baptisms", author: "Parish", citation_text: "Register 1685", url: "https://example.org/r",
                 repository: "Stadtarchiv Eisenach", source_type: "book" },
               { page: "folio 12", confidence: "very_high", text: "Anna, daughter of…", date: Date.new(1685, 3, 23) })

    ged = export
    assert_match(/0 @S\d+@ SOUR\n1 TITL Eisenach baptisms\n1 AUTH Parish\n1 TEXT Register 1685/, ged)
    assert_match(/2 SOUR @S\d+@\n3 PAGE folio 12\n3 DATA\n4 DATE 23 MAR 1685\n4 TEXT Anna, daughter of…\n3 QUAY 3/, ged)

    citation = reimport(ged).people.sole.events.sole.citations.sole
    assert_equal [ "folio 12", "very_high", "Anna, daughter of…", Date.new(1685, 3, 23) ],
      citation.values_at(:page, :confidence, :text, :date)
    assert_equal [ "Eisenach baptisms", "Parish", "Register 1685", "https://example.org/r", "Stadtarchiv Eisenach", "book" ],
      citation.source.values_at(:title, :author, :citation_text, :url, :repository, :source_type)
  end

  test "every confidence level maps to QUAY and back as documented" do
    expected = { "very_low" => [ 0, "low" ], "low" => [ 0, "low" ], "normal" => [ 1, "normal" ],
                 "high" => [ 2, "high" ], "very_high" => [ 3, "very_high" ] }

    expected.each do |confidence, (quay, back)|
      tree = shared_tree(confidence)
      tree.people.create!(given_names: "X").events.create!(kind: "BIRT")
        .cite({ title: "S" }, { confidence: confidence })

      ged = Gedcom::Writer.new(tree, user: @user).to_gedcom
      assert_match(/3 QUAY #{quay}/, ged)

      target = Tree.create!(name: "#{confidence} back")
      Gedcom::Mapper.new(Gedcom::Parser.new(ged).parse[:records], tree: target).import!
      assert_equal back, target.people.sole.events.sole.citations.sole.confidence
    end
  end

  test "unknown tags keep their sub-lines" do
    person(given_names: "Anna", gedcom_raw: [
      { "tag" => "CREM", "children" => [ { "tag" => "DATE", "value" => "1750" }, { "tag" => "PLAC", "value" => "Leipzig" } ] }
    ])

    ged = export
    assert_match(/1 CREM\n2 DATE 1750\n2 PLAC Leipzig/, ged)
    assert_equal ged.lines.grep(/CREM|1750|Leipzig/), export_of(reimport(ged)).lines.grep(/CREM|1750|Leipzig/)
  end

  test "unknown event sub-lines survive" do
    records = Gedcom::Parser.new(<<~GED).parse[:records]
      0 @I1@ INDI
      1 BIRT
      2 DATE 1685
      2 AGE 0
      2 NOTE Born at home
    GED
    Gedcom::Mapper.new(records, tree: @tree).import!

    assert_match(/1 BIRT\n2 DATE 1685\n2 AGE 0\n2 NOTE Born at home/, export)
  end

  test "a note record pointer becomes the biography" do
    imported = import_text(<<~GED)
      0 @I1@ INDI
      1 NAME Anna /Bach/
      1 NOTE @N1@
      0 @N1@ NOTE First line contin
      1 CONC ued
      1 CONT Second line
    GED

    assert_equal "First line continued\nSecond line", imported.people.sole.biography.to_plain_text
  end

  test "an event citation pointing at a source record with a repository is imported" do
    imported = import_text(<<~GED)
      0 @I1@ INDI
      1 BIRT
      2 SOUR @S1@
      3 PAGE p. 4
      3 QUAY 2
      0 @S1@ SOUR
      1 TITL Census 1897
      1 REPO @R1@
      0 @R1@ REPO
      1 NAME State Archive
    GED

    citation = imported.people.sole.events.sole.citations.sole
    assert_equal [ "p. 4", "high" ], citation.values_at(:page, :confidence)
    assert_equal [ "Census 1897", "State Archive" ], citation.source.values_at(:title, :repository)
  end

  test "a long biography is split into short lines and joined back without losing a character" do
    text = ("Johann Sebastian Bach was born in Eisenach. " * 12).strip
    person(given_names: "Anna", biography: "<div>#{text}</div>")

    ged = export
    assert ged.lines.all? { it.chomp.length <= 255 }
    assert_match(/^2 CONC /, ged)
    assert_equal text, reimport(ged).people.sole.biography.to_plain_text
  end

  test "a line break inside a value cannot start a new record" do
    person(given_names: "Anna\n0 @X1@ INDI")

    assert_no_match(/^0 @X1@/, export)
  end

  private
    def person(**attributes)
      @tree.people.create!(attributes)
    end

    def export = export_of(@tree)

    def export_of(tree) = Gedcom::Writer.new(tree, user: @user).to_gedcom

    def shared_tree(name)
      Tree.create!(name: name).tap { it.tree_memberships.create!(user: @user, role: "editor") }
    end

    def reimport(ged) = import_text(ged, tree: @target)

    def import_text(text, tree: @target)
      Gedcom::Mapper.new(Gedcom::Parser.new(text).parse[:records], tree: tree).import!
      tree
    end
end
