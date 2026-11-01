class Backup
  LOCAL_RETENTION = 7.days
  REQUIRED_TABLES = %w[ users trees people families events edits ].freeze

  class Invalid < StandardError; end

  class << self
    def create
      directory.mkpath
      path = directory.join("heartwood-#{Time.current.utc.strftime("%Y%m%dT%H%M%SZ")}.sqlite3.gz")

      Dir.mktmpdir do |dir|
        snapshot = File.join(dir, "snapshot.sqlite3")
        copy_live_database_to snapshot
        verify snapshot
        compress snapshot, path
      end

      upload path if offsite?
      prune
      path
    end

    # Run with the app stopped: the live database is replaced wholesale.
    def restore(path, to: primary_database_path)
      Dir.mktmpdir do |dir|
        snapshot = File.join(dir, "snapshot.sqlite3")
        decompress path, snapshot
        verify snapshot

        FileUtils.mv snapshot, to
        FileUtils.rm_f [ "#{to}-wal", "#{to}-shm" ]
      end
    end

    def directory
      Rails.configuration.x.backups.directory
    end

    private
      def offsite?
        Rails.configuration.x.backups.offsite
      end

      def copy_live_database_to(snapshot)
        destination = SQLite3::Database.new(snapshot)
        ApplicationRecord.with_connection do |connection|
          SQLite3::Backup.new(destination, "main", connection.raw_connection, "main").tap { it.step(-1) }.finish
        end
      ensure
        destination&.close
      end

      def verify(snapshot)
        database = SQLite3::Database.new(snapshot, readonly: true)
        raise Invalid, "integrity check failed" unless database.get_first_value("PRAGMA integrity_check") == "ok"

        tables = database.execute("SELECT name FROM sqlite_master WHERE type = 'table'").flatten
        missing = REQUIRED_TABLES - tables
        raise Invalid, "missing tables: #{missing.join(", ")}" if missing.any?
      rescue SQLite3::Exception => error
        raise Invalid, error.message
      ensure
        database&.close
      end

      def compress(source, destination)
        Zlib::GzipWriter.open(destination) { |gzip| File.open(source, "rb") { IO.copy_stream(it, gzip) } }
      end

      def decompress(source, destination)
        Zlib::GzipReader.open(source) { |gzip| File.open(destination, "wb") { IO.copy_stream(gzip, it) } }
      rescue Zlib::Error => error
        raise Invalid, error.message
      end

      def upload(path)
        File.open(path, "rb") do |file|
          ActiveStorage::Blob.services.fetch(:backups).upload("backups/#{path.basename}", file)
        end
      end

      def prune
        directory.glob("heartwood-*.sqlite3.gz").select { it.mtime < LOCAL_RETENTION.ago }.each(&:delete)
      end

      def primary_database_path
        Rails.root.join(ApplicationRecord.connection_db_config.database).to_s
      end
  end
end
