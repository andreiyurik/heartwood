module Person::Editable
  extend ActiveSupport::Concern

  include ::Editable

  class_methods do
    def restore(snapshot)
      links = snapshot.values_at("partner_memberships", "child_memberships")
      create!(snapshot.except("events", "partner_memberships", "child_memberships", "avatar_blob_id")).tap do |person|
        person.avatar.attach(ActiveStorage::Blob.find(snapshot["avatar_blob_id"])) if snapshot["avatar_blob_id"]
        Edit.suppress do
          snapshot["events"].each { |event| Event.restore(event) }
          FamilyPartner.restore_all(links.first)
          FamilyChild.restore_all(links.last)
        end
      end
    end
  end

  def snapshot
    super.merge \
      "biography"           => biography&.body&.to_html,
      "avatar_blob_id"      => avatar.blob&.id,
      "events"              => events.map(&:snapshot),
      "partner_memberships" => partner_memberships.map(&:snapshot),
      "child_memberships"   => child_memberships.map(&:snapshot)
  end

  def edited_person = self
end
