module Tree::Incineratable
  extend ActiveSupport::Concern

  def incinerate_later
    Tree::IncinerateJob.perform_later(self)
  end

  def incinerate
    photos = photo_blob_ids
    LiveUpdates.suppressing do
      transaction do
        duplicate_hints.delete_all
        destroy!
      end
    end
    ActiveStorage::Blob.where(id: photos).find_each(&:purge_later)
  end

  private
    # Avatars outlive their person for undo, so the people still here don't hold all of them.
    def photo_blob_ids
      ActiveStorage::Attachment.where(record_type: "Person", name: "avatar", record_id: people.select(:id)).pluck(:blob_id) +
        edits.person_removals.filter_map(&:kept_photo_blob_id)
    end
end
