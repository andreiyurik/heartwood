namespace :backup do
  desc "Snapshot, verify and (if configured) upload the primary database"
  task create: :environment do
    puts Backup.create
  end

  desc "Replace the primary database with a verified snapshot (stop the app first): FILE=path.sqlite3.gz"
  task restore: :environment do
    Backup.restore Pathname(ENV.fetch("FILE"))
    puts "Restored #{ENV.fetch("FILE")}"
  end
end
