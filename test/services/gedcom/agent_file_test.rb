require "test_helper"

# A file as the ex-ussr-kinship-research agent writes it: GEDCOM 5.5.1, Cyrillic, Old Style dates, archival
# references in PAGE, the evidence status in notes (docs/features/guides.md, docs/interop/gedcom.md).
class Gedcom::AgentFileTest < ActiveSupport::TestCase
  FILE = <<~GED
    0 HEAD
    1 SOUR ex-ussr-kinship-research
    1 GEDC
    2 VERS 5.5.1
    2 FORM LINEAGE-LINKED
    1 CHAR UTF-8
    0 @I1@ INDI
    1 NAME Иван Петрович /Сидоров/
    2 GIVN Иван Петрович
    2 SURN Сидоров
    1 SEX M
    1 REFN P-0001
    1 BIRT
    2 DATE @#DJULIAN@ 12 MAR 1885
    2 PLAC д. Горки, Ржевский уезд, Тверская губерния
    2 SOUR @S1@
    3 PAGE ф. 160, оп. 1, д. 2345, л. 12 об., запись 34
    3 DATA
    4 TEXT Родился 12, крещён 13 марта Иоанн; родители крестьянин Пётр Иванов и законная жена его Анна Фёдорова
    3 QUAY 3
    2 NOTE Статус: corroborated (C-0003). Дата по ст. ст.; по н. ст. 24 марта 1885.
    1 RELI православное
    1 DEAT Y
    2 NOTE Дата смерти не установлена.
    1 FAMC @F1@
    0 @I2@ INDI
    1 NAME Пётр /Иванов/
    1 SEX M
    1 FAMS @F1@
    0 @F1@ FAM
    1 HUSB @I2@
    1 CHIL @I1@
    1 NOTE Мать в записи названа; как отдельное лицо не установлена.
    0 @S1@ SOUR
    1 TITL Метрическая книга Успенской церкви с. Горки, 1885
    1 AUTH Тверская духовная консистория
    1 REPO @R1@
    0 @R1@ REPO
    1 NAME Государственный архив Тверской области
    0 TRLR
  GED

  setup do
    @user = users(:one)
    @tree = Tree.create!(name: "Сидоровы").tap { it.tree_memberships.create!(user: @user, role: "editor") }
    Gedcom::Mapper.new(Gedcom::Parser.new(FILE).parse[:records], tree: @tree).import!
    @ivan = @tree.people.find_by!(surname: "Сидоров")
  end

  test "an Old Style birth dates the person, so someone born in 1885 is not taken for a living person" do
    birth = @ivan.birth

    assert_equal Date.new(1885, 3, 24), birth.date_start
    assert_not @ivan.living?
    assert_equal "1885", @ivan.life_years.to_s.first(4)
    I18n.with_locale(:ru) { assert_equal "12 марта 1885 (ст. ст.)", birth.date_label }
  end

  test "the archival reference, the quote, the confidence and the archive arrive with the citation" do
    citation = @ivan.birth.citations.sole

    assert_equal "ф. 160, оп. 1, д. 2345, л. 12 об., запись 34", citation.page
    assert_match "крещён 13 марта Иоанн", citation.text
    assert_equal "very_high", citation.confidence
    assert_equal "Государственный архив Тверской области", citation.source.repository
  end

  test "the person is suggested the places to keep looking" do
    assert_includes ResearchSite.for(@ivan).map(&:key), "metric_books_familysearch"
  end

  test "the agent's notes and the calendar survive going back out to Gramps" do
    ged = Gedcom::Writer.new(@tree, user: @user).to_gedcom

    assert_match(/1 BIRT\n2 DATE @#DJULIAN@ 12 MAR 1885\n/, ged)
    assert_match "2 NOTE Статус: corroborated (C-0003).", ged
    assert_match "2 NOTE Дата смерти не установлена.", ged
    assert_match "1 NOTE Мать в записи названа", ged
    assert_match "1 REFN P-0001", ged
    assert_match "3 PAGE ф. 160, оп. 1, д. 2345, л. 12 об., запись 34", ged
  end
end
