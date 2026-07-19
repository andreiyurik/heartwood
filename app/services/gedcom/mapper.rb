module Gedcom
  class Mapper
    # Tags handled explicitly when nested under an INDI record.
    INDI_KNOWN = %w[NAME SEX BIRT DEAT BAPM BURI CHR OCCU RESI EDUC FAMS FAMC].freeze
    # Tags that map to Event records.
    EVENT_TAGS = %w[BIRT DEAT BAPM BURI CHR OCCU RESI EDUC MARR DIV].freeze

    def initialize(records, tree: nil)
      @tree     = tree || Current.tree
      @records  = records
      @warnings = []
      @xref_map = {}  # gedcom_xref string => saved AR object
      @people   = []
      @families = []
    end

    def import!
      ApplicationRecord.transaction do
        @records.each do |record|
          case record[:tag]
          when "INDI" then map_indi(record)
          when "FAM"  then map_fam(record)
          else
            @warnings << "Unknown top-level record: #{record[:tag]}"
          end
        end
      end

      # A fresh import is the most likely moment for duplicates to appear.
      DuplicateScanJob.perform_later(@tree)

      { people: @people, families: @families, warnings: @warnings }
    end

    private

    # --- INDI ---

    def map_indi(record)
      attrs    = { gedcom_xref: record[:xref], sex: "U" }
      raw_tags = []

      record[:children].each do |child|
        case child[:tag]
        when "SEX"  then attrs[:sex] = child[:value] if Person::SEXES.include?(child[:value])
        when "NAME" then extract_name(child, attrs)
        when *INDI_KNOWN
          # event tags are processed after save; other known tags are no-ops here
        else
          raw_tags << { "tag" => child[:tag], "value" => child[:value] }.compact
        end
      end

      attrs[:gedcom_raw] = raw_tags.presence

      person = Person.create!(attrs.merge(tree: @tree))
      @xref_map[record[:xref]] = person
      @people << person

      record[:children].each do |child|
        map_event(child, person) if EVENT_TAGS.include?(child[:tag])
      end

      person
    end

    # --- FAM ---

    def map_fam(record)
      fam      = Family.create!(gedcom_xref: record[:xref], tree: @tree)
      raw_tags = []

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
          raw_tags << { "tag" => child[:tag], "value" => child[:value] }.compact
        end
      end

      fam.update!(gedcom_raw: raw_tags) if raw_tags.any?
      fam
    end

    # --- Shared event mapping ---

    def map_event(record, eventable)
      date_child = record[:children].find { |c| c[:tag] == "DATE" }
      plac_child = record[:children].find { |c| c[:tag] == "PLAC" }

      # PLAC stays in `value` for a lossless round-trip; it also seeds a normalized
      # Place so imported events can earn map pins (see place.md).
      eventable.events.create!(
        kind:       record[:tag],
        date_raw:   date_child&.[](:value),
        value:      plac_child&.[](:value),
        place_name: plac_child&.[](:value)
      )
    end

    # --- Helpers ---

    # Populate given_names / surname from a NAME record.
    # Prefers GIVN/SURN sub-tags; falls back to parsing the NAME value string.
    def extract_name(name_record, attrs)
      givn = name_record[:children].find { |c| c[:tag] == "GIVN" }
      surn = name_record[:children].find { |c| c[:tag] == "SURN" }

      if givn || surn
        attrs[:given_names] = givn&.[](:value)
        attrs[:surname]     = surn&.[](:value)
      elsif (val = name_record[:value])
        # GEDCOM surname convention: surname is wrapped in slashes — "Johann /Bach/"
        if (m = val.match(/\A(.*?)\s*\/([^\/]*)\//))
          attrs[:given_names] = m[1].strip.presence
          attrs[:surname]     = m[2].strip.presence
        else
          attrs[:given_names] = val
        end
      end
    end

    def resolve_xref(xref)
      obj = @xref_map[xref]
      @warnings << "Unresolved xref: #{xref}" unless obj
      obj
    end
  end
end
