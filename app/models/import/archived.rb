# A .zip/.gdz in the GEDZIP layout: a .ged at the root plus the files its OBJE records point at.
module Import::Archived
  extend ActiveSupport::Concern

  private
    def archive?
      file.filename.extension_without_delimiter.downcase.in?(%w[zip gdz])
    end

    # Entries are read by name, never extracted, so a path like "../x" can't reach the disk.
    def read_archive
      file.open do |tempfile|
        Zip::File.open(tempfile.path) do |zip|
          gedcom = zip.find_entry("gedcom.ged") || zip.glob("*.ged").first
          raise Zip::Error, "no GEDCOM inside" unless gedcom

          yield gedcom.get_input_stream.read, ->(path) { photo_from(zip, path) }
        end
      end
    end

    def photo_from(zip, path)
      entry = zip.find_entry(path.tr("\\", "/").delete_prefix("./"))
      return unless entry&.file? && entry.size <= Person::AVATAR_MAX_BYTES

      content_type = Marcel::MimeType.for(name: entry.name)
      return unless content_type.in?(Person::AVATAR_CONTENT_TYPES)

      { io: StringIO.new(entry.get_input_stream.read), filename: File.basename(entry.name), content_type: content_type }
    end
end
