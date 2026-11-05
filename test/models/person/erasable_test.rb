require "test_helper"

class Person::ErasableTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper

  setup do
    Current.session = users(:bach).sessions.create!
    Current.tree = trees(:bach)
    @person = people(:wilhelm_friedemann)
  end

  test "erasing a person keeps no copy to undo and no history about them" do
    @person.events.create!(kind: "BIRT", date_raw: "1710")
    @person.update!(nickname: "Friedemann")

    assert_no_difference -> { Edit.where.not(person_id: @person.id).count } do
      @person.erase
    end

    assert_not Person.exists?(@person.id)
    assert_equal 0, Event.where(eventable: @person).count
    assert_equal 0, Edit.where(person_id: @person.id).count
    assert_equal 0, Edit.where(subject_type: "Person", subject_id: @person.id).count
  end

  test "erasing a person purges their photo and photos kept by earlier removals" do
    photo = attach_photo(@person)
    @person.destroy!
    Edit.person_removals.last.revert(by: users(:bach))
    restored = Person.find(@person.id)
    restored.avatar.detach
    newer = attach_photo(restored)

    perform_enqueued_jobs { restored.reload.erase }

    assert_not ActiveStorage::Blob.exists?(photo.id)
    assert_not ActiveStorage::Blob.exists?(newer.id)
  end

  test "no history row about anyone else keeps the erased name" do
    barbara = people(:maria_barbara)
    families(:first_marriage).events.create!(kind: "MARR", date_raw: "1707", place_name: "Dornheim")
    barbara.update!(given_names: "Мария Барбара")
    FamilyChild.create!(family: families(:first_marriage), person: Person.create!(given_names: "Child", sex: "U", tree: trees(:bach)), tree: trees(:bach))

    assert Edit.where("particulars LIKE ?", "%Barbara%").exists?
    assert Edit.where("particulars LIKE ?", "%Барбара%").exists?

    barbara.reload.erase

    assert_equal 0, Edit.where("particulars LIKE ?", "%Barbara%").count
    assert_equal 0, Edit.where("particulars LIKE ?", "%Барбара%").count
  end

  test "an erased partner takes the couple's events, and an emptied family goes too" do
    barbara = people(:maria_barbara)
    alone = Family.create!(tree: trees(:bach))
    FamilyPartner.create!(family: alone, person: barbara, tree: trees(:bach))
    marriage = families(:first_marriage).events.create!(kind: "MARR", date_raw: "1707")

    barbara.erase

    assert_not Family.exists?(alone.id)
    assert Family.exists?(families(:first_marriage).id)
    assert_not Event.exists?(marriage.id)
  end

  test "places and sources only the erased person used are erased too" do
    shared = places(:leipzig)
    own = Place.create!(name: "Tver, Sovetskaya 12-34", tree: trees(:bach))
    @person.events.create!(kind: "RESI", place: own)
    @person.events.create!(kind: "RESI", place: shared).cite({ title: "Passport of Friedemann" })

    @person.erase

    assert_not Place.exists?(own.id)
    assert Place.exists?(shared.id)
    assert_not Source.exists?(title: "Passport of Friedemann")
  end

  test "download archives and import uploads, which hold everyone, are purged" do
    archive = Archive.create!(tree: trees(:bach), user: users(:bach))
    import = Import.new(tree: trees(:bach), user: users(:bach))
    import.file.attach(io: StringIO.new("0 HEAD"), filename: "tree.ged")
    import.save!

    perform_enqueued_jobs { @person.erase }

    assert_not Archive.exists?(archive.id)
    assert_not import.reload.file.attached?
  end

  private
    def attach_photo(person)
      person.avatar.attach(io: StringIO.new("\x89PNG\r\n\x1a\n" + "\x00" * 100), filename: "p.png", content_type: "image/png")
      person.avatar.blob
    end
end
