module Archive::Media
  extend ActiveSupport::Concern

  private
    # Returns the media map Gedcom::Writer expects, listing only the files actually written.
    def write_media(zip)
      count = 0

      people_with_media.each_with_object({}) do |person, media|
        blobs_of(person).each_with_index do |(blob, primary), index|
          next unless blob.service.exist?(blob.key)

          path = "media/#{slug(person)}#{"-#{index + 1}" if index > 0}.#{extension(blob)}"
          zip.put_next_entry(path)
          blob.download { zip.write it }

          (media[person.id] ||= []) << { xref: "@O#{count += 1}@", path: path, form: extension(blob), primary: primary }
        end
      end
    end

    def people_with_media
      tree.people.visible_to(user).includes(:rich_text_biography, avatar_attachment: :blob).order(:id)
    end

    def blobs_of(person)
      pictures = person.biography&.body&.attachables.to_a.grep(ActiveStorage::Blob)
      [ ([ person.avatar.blob, true ] if person.avatar.attached?), *pictures.map { [ it, false ] } ].compact
    end

    def slug(person)
      person.gedcom_xref.to_s.gsub(/[^A-Za-z0-9_-]/, "").presence || "I#{person.id}"
    end

    def extension(blob)
      blob.filename.extension_without_delimiter.downcase.presence || Marcel::Magic.new(blob.content_type).extensions.first || "bin"
    end
end
