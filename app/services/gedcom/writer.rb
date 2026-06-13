module Gedcom
  # Serialises a Tree (or a subset of it) to GEDCOM 5.5.1 text.
  # Privacy: `user` governs visibility — Person.visible_to(user) is applied so
  # living people are never emitted to non-members.
  class Writer
    def initialize(tree, user: nil)
      @tree = tree
      @user = user
    end

    def to_gedcom
      people = @tree.people
                    .visible_to(@user)
                    .includes(:events, :families_as_partner, :families_as_child)
      visible_ids = people.map(&:id).to_set

      fam_ids = Set.new
      people.each do |p|
        p.families_as_partner.each { |f| fam_ids << f.id }
        p.families_as_child.each   { |f| fam_ids << f.id }
      end
      families = Family.where(id: fam_ids.to_a)
                       .includes(:events, :partners, :children)

      parts = [ header ]
      people.each   { |p| parts << indi_block(p) }
      families.each { |f| parts << fam_block(f, visible_ids) }
      parts << "0 TRLR"
      parts.join("\n")
    end

    private

    def header
      "0 HEAD\n1 GEDC\n2 VERS 5.5.1\n2 FORM LINEAGE-LINKED\n1 CHAR UTF-8"
    end

    def person_xref(person)
      person.gedcom_xref || "@I#{person.id}@"
    end

    def family_xref(family)
      family.gedcom_xref || "@F#{family.id}@"
    end

    def indi_block(person)
      lines = [ "0 #{person_xref(person)} INDI" ]

      if person.given_names.present? || person.surname.present?
        name_val = [
          person.given_names.presence,
          person.surname.present? ? "/#{person.surname}/" : nil
        ].compact.join(" ")
        lines << "1 NAME #{name_val}"
        lines << "2 GIVN #{person.given_names}" if person.given_names.present?
        lines << "2 SURN #{person.surname}"     if person.surname.present?
      end

      lines << "1 SEX #{person.sex}"

      person.events.order(:id).each { |ev| append_event(lines, ev, level: 1) }

      person.families_as_partner.each { |f| lines << "1 FAMS #{family_xref(f)}" }
      person.families_as_child.each   { |f| lines << "1 FAMC #{family_xref(f)}" }

      Array(person.gedcom_raw).each do |raw|
        lines << "1 #{raw['tag']} #{raw['value']}".strip
      end

      lines.join("\n")
    end

    def fam_block(family, visible_ids)
      lines = [ "0 #{family_xref(family)} FAM" ]

      family.partners.select { |p| visible_ids.include?(p.id) }.sort_by(&:id).each do |p|
        tag = p.sex == "F" ? "WIFE" : "HUSB"
        lines << "1 #{tag} #{person_xref(p)}"
      end

      family.children.select { |c| visible_ids.include?(c.id) }.sort_by(&:id).each do |c|
        lines << "1 CHIL #{person_xref(c)}"
      end

      family.events.order(:id).each { |ev| append_event(lines, ev, level: 1) }

      Array(family.gedcom_raw).each do |raw|
        lines << "1 #{raw['tag']} #{raw['value']}".strip
      end

      lines.join("\n")
    end

    def append_event(lines, event, level:)
      lines << "#{level} #{event.kind}"
      lines << "#{level + 1} DATE #{event.date_raw}" if event.date_raw.present?
      lines << "#{level + 1} PLAC #{event.value}"    if event.value.present?
    end
  end
end
