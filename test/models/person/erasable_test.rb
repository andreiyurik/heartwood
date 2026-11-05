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

  private
    def attach_photo(person)
      person.avatar.attach(io: StringIO.new("\x89PNG\r\n\x1a\n" + "\x00" * 100), filename: "p.png", content_type: "image/png")
      person.avatar.blob
    end
end
