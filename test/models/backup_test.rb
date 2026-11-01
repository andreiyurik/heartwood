require "test_helper"

class BackupTest < ActiveSupport::TestCase
  setup do
    @shared_directory = Backup.directory
    Rails.configuration.x.backups.directory = @shared_directory.join(Process.pid.to_s)
    @offsite = ActiveStorage::Blob.services.fetch(:backups)
  end

  teardown do
    FileUtils.rm_rf Backup.directory
    Rails.configuration.x.backups.directory = @shared_directory
  end

  test "creates a compressed snapshot that restores to the same data" do
    path = Backup.create

    assert_match(/heartwood-\d{8}T\d{6}Z\.sqlite3\.gz\z/, path.basename.to_s)

    Dir.mktmpdir do |dir|
      restored = File.join(dir, "restored.sqlite3")
      Backup.restore(path, to: restored)

      database = SQLite3::Database.new(restored)
      assert_equal Person.count, database.get_first_value("SELECT count(*) FROM people")
      assert_equal Tree.count, database.get_first_value("SELECT count(*) FROM trees")
      assert_equal User.count, database.get_first_value("SELECT count(*) FROM users")
    ensure
      database&.close
    end
  end

  test "sends every snapshot off-site" do
    path = Backup.create

    assert @offsite.exist?("backups/#{path.basename}")
  end

  test "keeps only a week of local snapshots" do
    stale = Backup.directory.tap(&:mkpath).join("heartwood-20200101T000000Z.sqlite3.gz")
    FileUtils.touch stale, mtime: (Backup::LOCAL_RETENTION + 1.day).ago.to_time

    fresh = Backup.create

    assert_not stale.exist?
    assert fresh.exist?
  end

  test "refuses to restore a damaged snapshot" do
    damaged = Backup.directory.tap(&:mkpath).join("damaged.sqlite3.gz")
    Zlib::GzipWriter.open(damaged) { it.write "SQLite format 3\0" + "garbage" * 500 }

    Dir.mktmpdir do |dir|
      target = File.join(dir, "live.sqlite3")
      File.write(target, "the live database")

      assert_raises(Backup::Invalid) { Backup.restore(damaged, to: target) }
      assert_equal "the live database", File.read(target)
    end
  end
end
