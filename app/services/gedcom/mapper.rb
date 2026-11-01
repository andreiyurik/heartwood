module Gedcom
  class Mapper
    EVENT_TAGS = %w[BIRT DEAT BAPM BURI CHR OCCU RESI EDUC MARR DIV].freeze
    NAME_PARTS = { "NPFX" => :name_prefix, "GIVN" => :given_names, "NICK" => :nickname,
                   "SURN" => :surname, "NSFX" => :name_suffix }.freeze
    QUAY       = { "0" => "low", "1" => "normal", "2" => "high", "3" => "very_high" }.freeze
    REFERENCED = %w[NOTE SOUR REPO OBJE SUBM].freeze

    # media: resolves an OBJE FILE path to an attachable (a GEDZIP's files), or nil.
    def initialize(records, tree: nil, media: nil)
      @tree     = tree || Current.tree
      @records  = records
      @media    = media
      @warnings = []
      @xref_map = {}
      @people   = []
      @families = []
      @by_xref  = records.select { it[:xref] }.index_by { it[:xref] }
      @sources  = {}
    end

    def import!
      ApplicationRecord.transaction do
        @records.each do |record|
          case record[:tag]
          when "INDI" then map_indi(record)
          when "FAM"  then map_fam(record)
          when *REFERENCED
          else
            @warnings << "Unknown top-level record: #{record[:tag]}"
          end
        end
      end

      # A fresh import is the likeliest moment for duplicates.
      DuplicateScanJob.perform_later(@tree)

      { people: @people, families: @families, warnings: @warnings }
    end

    private
      def map_indi(record)
        attrs = { gedcom_xref: record[:xref], sex: "U" }
        raw   = []
        notes = []
        named = false

        record[:children].each do |child|
          case child[:tag]
          when "SEX"  then attrs[:sex] = child[:value] if Person::SEXES.include?(child[:value])
          when "NAME"
            if named
              raw << raw_node(child)
            else
              named = true
              raw.concat extract_name(child, attrs)
            end
          when "NOTE" then notes << note_text(child)
          when *EVENT_TAGS, "FAMS", "FAMC", "OBJE"
          else
            raw << raw_node(child)
          end
        end

        photo, others = pick_photo(record[:children].select { it[:tag] == "OBJE" })
        raw.concat others.map { raw_node(dereference(it)) }

        attrs[:gedcom_raw] = raw.presence
        attrs[:biography]  = biography_html(notes) if notes.any?

        person = Person.create!(attrs.merge(tree: @tree))
        person.avatar.attach(photo) if photo
        @xref_map[record[:xref]] = person
        @people << person

        record[:children].each do |child|
          map_event(child, person) if EVENT_TAGS.include?(child[:tag])
        end

        person
      end

      def map_fam(record)
        fam = Family.create!(gedcom_xref: record[:xref], tree: @tree)
        raw = []

        @xref_map[record[:xref]] = fam
        @families << fam

        record[:children].each do |child|
          case child[:tag]
          when "HUSB", "WIFE"
            if (person = resolve_xref(child[:value]))
              fam.partners << person
            end
          when "CHIL"
            if (person = resolve_xref(child[:value]))
              fam.children << person
            end
          when *EVENT_TAGS
            map_event(child, fam)
          else
            raw << raw_node(child)
          end
        end

        fam.update!(gedcom_raw: raw) if raw.any?
        fam
      end

      def map_event(record, eventable)
        date  = record[:children].find { it[:tag] == "DATE" }&.dig(:value)
        date  = date[/\A\((.*)\)\z/, 1] || date if date # a date phrase
        place = record[:children].find { it[:tag] == "PLAC" }&.dig(:value)
        raw   = record[:children].reject { it[:tag].in?(%w[DATE PLAC SOUR]) }.map { raw_node(it) }

        # PLAC stays in `value` for a lossless round-trip and also seeds a Place for map pins.
        event = eventable.events.create!(kind: record[:tag], date_raw: date, value: place, place_name: place,
                                         gedcom_raw: raw.presence)

        record[:children].select { it[:tag] == "SOUR" }.each { map_citation(it, event) }
      end

      def map_citation(record, event)
        data = record[:children].find { it[:tag] == "DATA" }

        event.citations.create!(
          source:     source_for(record),
          page:       child_value(record, "PAGE"),
          confidence: QUAY.fetch(child_value(record, "QUAY").to_s, "normal"),
          text:       (text_of(data, "TEXT") if data),
          date:       parse_date(data && child_value(data, "DATE"))
        )
      end

      def source_for(citation)
        xref = citation[:value]
        return @sources[xref] ||= create_source(@by_xref[xref]) if @by_xref[xref]&.dig(:tag) == "SOUR"

        @warnings << "Unresolved xref: #{xref}" if xref&.match?(/\A@.+@\z/)
        @tree.sources.create!(title: note_text(citation).presence || "—")
      end

      def create_source(record)
        @tree.sources.create!(
          title:         child_value(record, "TITL").presence || "—",
          author:        child_value(record, "AUTH"),
          citation_text: text_of(record, "TEXT"),
          url:           child_value(record, "WWW"),
          repository:    repository_name(record[:children].find { it[:tag] == "REPO" }),
          source_type:   child_value(record, "_TYPE")
        )
      end

      def repository_name(node)
        return unless node
        repository = dereference(node)
        child_value(repository, "NAME") || (node[:value] unless node[:value]&.start_with?("@"))
      end

      # Returns the NAME sub-lines Heartwood has no field for, so they reach the raw store.
      def extract_name(name_record, attrs)
        parts, rest = name_record[:children].partition { NAME_PARTS.key?(it[:tag]) }
        parts.each { attrs[NAME_PARTS.fetch(it[:tag])] = it[:value] }

        if parts.none? { it[:tag].in?(%w[GIVN SURN]) } && (value = name_record[:value])
          # GEDCOM wraps the surname in slashes: "Johann /Bach/".
          if (match = value.match(/\A(.*?)\s*\/([^\/]*)\//))
            attrs[:given_names] = match[1].strip.presence
            attrs[:surname]     = match[2].strip.presence
          else
            attrs[:given_names] = value
          end
        end

        rest.map { raw_node(it) }
      end

      def note_text(node)
        node = dereference(node)
        node[:children].each_with_object(node[:value].to_s.dup) do |child, text|
          case child[:tag]
          when "CONT" then text << "\n" << child[:value].to_s
          when "CONC" then text << child[:value].to_s
          end
        end
      end

      def text_of(record, tag)
        node = record[:children].find { it[:tag] == tag }
        note_text(node) if node
      end

      def biography_html(notes)
        notes.join("\n\n").split("\n", -1).map { "<div>#{it.empty? ? "<br>" : ERB::Util.html_escape(it)}</div>" }.join
      end

      # The link marked _PRIM Y, else the first not marked _PRIM N, if its file can be attached.
      def pick_photo(links)
        primary = links.find { child_value(it, "_PRIM") == "Y" } || links.find { child_value(it, "_PRIM") != "N" }
        photo   = attachable(dereference(primary)) if primary

        photo ? [ photo, links - [ primary ] ] : [ nil, links ]
      end

      def attachable(object)
        file = object[:children].find { it[:tag] == "FILE" }&.dig(:value)
        @media&.call(file) if file
      end

      def dereference(node)
        target = @by_xref[node[:value]] if node[:value]&.match?(/\A@.+@\z/)
        target || node
      end

      def raw_node(node)
        { "tag" => node[:tag], "value" => node[:value],
          "children" => node[:children].map { raw_node(it) }.presence }.compact
      end

      def child_value(record, tag)
        record[:children].find { it[:tag] == tag }&.dig(:value)
      end

      def parse_date(value)
        Date.strptime(value, "%d %b %Y") if value
      rescue Date::Error
        nil
      end

      def resolve_xref(xref)
        obj = @xref_map[xref]
        @warnings << "Unresolved xref: #{xref}" unless obj
        obj
      end
  end
end
