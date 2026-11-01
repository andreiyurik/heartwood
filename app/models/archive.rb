class Archive < ApplicationRecord
  include Media

  RETENTION = 24.hours

  belongs_to :tree
  belongs_to :user
  has_one_attached :file

  enum :status, %w[pending processing completed failed].index_by(&:itself), default: "pending"

  scope :expired, -> { where(created_at: ...RETENTION.ago) }

  broadcasts_refreshes

  def self.prune
    expired.find_each(&:destroy!)
  end

  def build_later
    ArchiveJob.perform_later(self)
  end

  def build
    processing!

    Tempfile.create([ "archive", ".zip" ], binmode: true) do |tempfile|
      Zip::OutputStream.open(tempfile.path) do |zip|
        media = write_media(zip)
        zip.put_next_entry("gedcom.ged")
        zip.write Gedcom::Writer.new(tree, user: user, media: media).to_gedcom
      end

      File.open(tempfile.path, "rb") { file.attach(io: it, filename: filename, content_type: "application/zip") }
    end

    completed!
  rescue
    failed!
    raise
  end

  private
    def filename
      "#{tree.name} #{created_at.to_date}.zip"
    end
end
