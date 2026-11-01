require "test_helper"

class ArchiveTest < ActiveSupport::TestCase
  PNG = "\x89PNG\r\n\x1a\n".b + ("\x00" * 64).b

  setup do
    @tree   = trees(:alpha)
    @user   = users(:one)
    @person = @tree.people.create!(given_names: "Anna", gedcom_xref: "@I7@")
    @person.avatar.attach(io: StringIO.new(PNG), filename: "anna.png", content_type: "image/png")
  end

  test "build zips the GEDCOM and every photo, referenced by relative paths" do
    archive = build_archive

    assert archive.completed?
    assert archive.file.attached?
    assert_equal "application/zip", archive.file.content_type

    entries = zip_entries(archive)
    assert_equal PNG, entries.fetch("media/I7.png")
    assert_match(/1 OBJE @O1@\n2 _PRIM Y/, entries.fetch("gedcom.ged"))
    assert_match(/0 @O1@ OBJE\n1 FILE media\/I7\.png\n2 FORM png/, entries.fetch("gedcom.ged"))
  end

  test "pictures in the biography go in too, without becoming the photo" do
    picture = ActiveStorage::Blob.create_and_upload!(io: StringIO.new(PNG), filename: "letter.png", content_type: "image/png")
    @person.update!(biography: %(<div>A letter</div><action-text-attachment sgid="#{picture.attachable_sgid}"></action-text-attachment>))

    ged = zip_entries(build_archive).fetch("gedcom.ged")

    assert_match(/1 OBJE @O2@\n2 _PRIM N/, ged)
    assert_match(/1 FILE media\/I7-2\.png/, ged)
  end

  test "photos come back when the archive is imported" do
    archive = build_archive
    target  = trees(:beta)

    import = Import.new(tree: target, user: users(:two))
    import.file.attach(io: StringIO.new(archive.file.download), filename: "tree.zip")
    import.save!
    import.process

    assert import.completed?, import.error
    anna = target.people.find_by!(given_names: "Anna")
    assert anna.avatar.attached?
    assert_equal PNG, anna.avatar.download
  end

  test "an archive is only for the member who asked for it" do
    archive = @tree.archives.create!(user: @user)

    assert_includes @user.archives, archive
    assert_not_includes users(:two).archives, archive
  end

  test "prune purges archives older than a day" do
    old   = @tree.archives.create!(user: @user, created_at: (Archive::RETENTION + 1.hour).ago)
    fresh = @tree.archives.create!(user: @user)

    Archive.prune

    assert_not Archive.exists?(old.id)
    assert Archive.exists?(fresh.id)
  end

  test "a photo missing from storage is left out instead of failing the whole archive" do
    @person.avatar.blob.service.delete(@person.avatar.blob.key)

    archive = build_archive

    assert archive.completed?
    assert_equal [ "gedcom.ged" ], zip_entries(archive).keys
    assert_no_match(/OBJE/, zip_entries(archive).fetch("gedcom.ged"))
  end

  private
    def build_archive
      @tree.archives.create!(user: @user).tap(&:build)
    end

    def zip_entries(archive)
      {}.tap do |entries|
        Zip::File.open_buffer(archive.file.download) { |zip| zip.each { entries[it.name] = it.get_input_stream.read } }
      end
    end
end
