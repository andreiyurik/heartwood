module Gedcom
  # Person.visible_to(user) keeps living people out of exports for non-members.
  class Writer
    QUAY   = { "very_low" => 0, "low" => 0, "normal" => 1, "high" => 2, "very_high" => 3 }.freeze
    MONTHS = %w[JAN FEB MAR APR MAY JUN JUL AUG SEP OCT NOV DEC].freeze
    CHUNK  = 200

    # media: { person_id => [ { xref:, path:, form:, primary: } ] } — only an archive has files to point at.
    def initialize(tree, user: nil, media: {})
      @tree  = tree
      @user  = user
      @media = media
    end

    def to_gedcom
      @lines = [ "0 HEAD", "1 GEDC", "2 VERS 5.5.1", "2 FORM LINEAGE-LINKED", "1 CHAR UTF-8" ]

      people.each { |person| write_person(person) }
      families.each { |family| write_family(family) }
      sources.each { |source| write_source(source) }
      repositories.each { |name, xref| write_repository(name, xref) }
      @media.values.flatten.each { |file| write_media(file) }

      @lines << "0 TRLR"
      @lines.join("\n")
    end

    private
      def people
        @people ||= @tree.people.visible_to(@user)
          .includes(:rich_text_biography, :families_as_partner, :families_as_child, events: { citations: :source })
          .order(:id).to_a
      end

      def visible_ids
        @visible_ids ||= people.map(&:id).to_set
      end

      def families
        ids = people.flat_map { |person| person.families_as_partner.map(&:id) + person.families_as_child.map(&:id) }.uniq
        Family.where(id: ids).includes(:partners, :children, events: { citations: :source }).order(:id)
      end

      def sources
        @sources ||= if @user && @tree.users.exists?(@user.id)
          @tree.sources.order(:id).to_a
        else
          cited = people.flat_map(&:events).flat_map(&:citations).map(&:source_id)
          @tree.sources.where(id: cited).order(:id).to_a
        end
      end

      def repositories
        @repositories ||= sources.filter_map { it.repository.presence }.uniq
          .each_with_index.to_h { |name, index| [ name, "@R#{index + 1}@" ] }
      end

      def write_person(person)
        line 0, "INDI", xref: person.gedcom_xref || "@I#{person.id}@"
        write_name(person) if person.given_names.present? || person.surname.present?
        line 1, "SEX", person.sex

        person.events.sort_by(&:id).each { |event| write_event(event) }
        line 1, "NOTE", person.biography.to_plain_text if person.biography.present?

        Array(@media[person.id]).each do |file|
          line 1, "OBJE", file[:xref]
          line 2, "_PRIM", file[:primary] ? "Y" : "N"
        end
        person.families_as_partner.each { |family| line 1, "FAMS", family_xref(family) }
        person.families_as_child.each { |family| line 1, "FAMC", family_xref(family) }
        write_raw(person.gedcom_raw, level: 1)
      end

      def write_name(person)
        line 1, "NAME", [ person.given_names.presence, ("/#{person.surname}/" if person.surname.present?) ].compact.join(" ")
        line 2, "NPFX", person.name_prefix
        line 2, "GIVN", person.given_names
        line 2, "NICK", person.nickname
        line 2, "SURN", person.surname
        line 2, "NSFX", person.name_suffix
      end

      def write_family(family)
        line 0, "FAM", xref: family_xref(family)

        family.partners.select { visible_ids.include?(it.id) }.sort_by(&:id).each do |partner|
          line 1, partner.sex == "F" ? "WIFE" : "HUSB", person_xref(partner)
        end
        family.children.select { visible_ids.include?(it.id) }.sort_by(&:id).each do |child|
          line 1, "CHIL", person_xref(child)
        end

        family.events.sort_by(&:id).each { |event| write_event(event) }
        write_raw(family.gedcom_raw, level: 1)
      end

      def write_event(event)
        line 1, event.kind
        line 2, "DATE", event.date_raw
        line 2, "PLAC", event.value
        event.citations.sort_by(&:id).each { |citation| write_citation(citation) }
        write_raw(event.gedcom_raw, level: 2)
      end

      def write_citation(citation)
        line 2, "SOUR", "@S#{citation.source_id}@"
        line 3, "PAGE", citation.page
        if citation.date || citation.text.present?
          line 3, "DATA"
          line 4, "DATE", gedcom_date(citation.date)
          line 4, "TEXT", citation.text
        end
        line 3, "QUAY", QUAY.fetch(citation.confidence)
      end

      def write_source(source)
        line 0, "SOUR", xref: "@S#{source.id}@"
        line 1, "TITL", source.title
        line 1, "AUTH", source.author
        line 1, "TEXT", source.citation_text
        line 1, "WWW", source.url
        line 1, "REPO", repositories[source.repository]
        line 1, "_TYPE", source.source_type
      end

      def write_repository(name, xref)
        line 0, "REPO", xref: xref
        line 1, "NAME", name
      end

      def write_media(file)
        line 0, "OBJE", xref: file[:xref]
        line 1, "FILE", file[:path]
        line 2, "FORM", file[:form]
      end

      def write_raw(nodes, level:)
        Array(nodes).each do |node|
          node["value"].nil? ? line(level, node["tag"]) : line(level, node["tag"], node["value"])
          write_raw(node["children"], level: level + 1)
        end
      end

      # Splits on newlines (CONT) and long lines (CONC), so no value can break the record structure.
      def line(level, tag, value = :none, xref: nil)
        return emit(level, tag, "", xref: xref) if value == :none

        text = value.to_s
        return if text.blank?

        first, *rest = text.split(/\r?\n/, -1)
        emit level, tag, first, xref: xref
        rest.each { emit level + 1, "CONT", it }
      end

      def emit(level, tag, text, xref: nil)
        head, *tail = chunks(text)
        @lines << [ level, xref, tag, head.presence ].compact.join(" ")
        tail.each { @lines << "#{level + 1} CONC #{it}" }
      end

      # Never cut next to a space: readers strip the ends of every line.
      def chunks(text)
        parts = []
        while text.length > CHUNK
          cut = CHUNK
          cut -= 1 while cut > 1 && (text[cut - 1] == " " || text[cut] == " ")
          parts << text[0...cut]
          text = text[cut..]
        end
        parts << text
      end

      def gedcom_date(date)
        "#{date.day} #{MONTHS[date.month - 1]} #{date.year}" if date
      end

      def person_xref(person) = person.gedcom_xref || "@I#{person.id}@"
      def family_xref(family) = family.gedcom_xref || "@F#{family.id}@"
  end
end
