module Person::Erasable
  extend ActiveSupport::Concern

  # A subject's demand for removal (ст. 21 152-ФЗ) rules out the 90-day copy an ordinary removal keeps for undo.
  def erase
    history = Edit.where(person_id: id)
    kept_photos = history.person_removals.filter_map(&:kept_photo_blob_id)

    transaction do
      history.delete_all
      avatar.purge_later if avatar.attached?
      Edit.suppress { destroy! }
    end

    ActiveStorage::Blob.where(id: kept_photos).where.missing(:attachments).find_each(&:purge_later)
  end
end
