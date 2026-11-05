module Person::Erasable
  extend ActiveSupport::Concern

  NAME_ATTRIBUTES = %w[ name_prefix given_names nickname surname name_suffix ].freeze

  # A subject's demand for removal (ст. 21 152-ФЗ) rules out the 90-day copy an ordinary removal keeps for undo,
  # and every other place their details linger: the couple's events, other people's history, places, sources, exports.
  def erase
    history = Edit.where(person_id: id)
    photos = [ avatar.blob&.id, *history.person_removals.filter_map(&:kept_photo_blob_id) ].compact
    names = [ display_name, *history.filter_map { it.particulars["name"] }, *former_names(history) ].compact_blank.uniq
    couples = families_as_partner.to_a
    places = events.filter_map(&:place_id)
    sources = Citation.where(citable: events).pluck(:source_id)

    transaction do
      Edit.suppress do
        history.delete_all
        edits_naming(names).delete_all
        avatar.detach
        couples.each { it.events.destroy_all }
        destroy!
        couples.each { it.destroy! if it.partners.none? && it.children.none? }
        tree.places.where(id: places).where.missing(:events).destroy_all
        tree.sources.where(id: sources).where.missing(:citations).destroy_all
        tree.archives.destroy_all
      end
    end

    tree.imports.each { it.file.purge_later }
    ActiveStorage::Blob.where(id: photos).where.missing(:attachments).find_each(&:purge_later)
  end

  private
    def former_names(history)
      history.filter_map { it.particulars["before"]&.slice(*NAME_ATTRIBUTES).presence }
        .map { Person.new(attributes.slice(*NAME_ATTRIBUTES).merge(it)).display_name }
    end

    def edits_naming(names)
      names.reduce(tree.edits.none) do |edits, name|
        edits.or(tree.edits.where("particulars LIKE ?", "%#{Edit.sanitize_sql_like(name)}%"))
      end
    end
end
