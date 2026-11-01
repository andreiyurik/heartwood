module EditsHelper
  DERIVED_ATTRIBUTES = %w[ date_start date_end date_precision gedcom_raw gedcom_xref tree_id ].freeze

  def edit_subject(edit)
    if edit.person
      link_to edit.person.display_name, edit.person
    else
      edit.particulars["name"] || t("edits.family", names: Array(edit.particulars["family"]).to_sentence)
    end
  end

  def edit_description(edit)
    t "edits.#{edit.subject_type.underscore}.#{edit.action}",
      fields: edit_fields(edit), kind: edit_kind(edit), relatives: edit_relatives(edit)
  end

  private
    def edit_fields(edit)
      model = edit.subject_type.constantize
      (Array(edit.particulars["before"]&.keys) - DERIVED_ATTRIBUTES)
        .map { |attribute| model.human_attribute_name(attribute).downcase }.uniq.to_sentence
    end

    def edit_kind(edit)
      kind = edit.particulars["kind"]
      t("events.kinds.#{kind}", default: Event::KINDS.fetch(kind, kind.to_s)).downcase if kind
    end

    def edit_relatives(edit)
      Array(edit.particulars["relatives"]).to_sentence.presence || t("edits.no_relatives")
    end
end
