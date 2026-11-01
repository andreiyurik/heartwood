module FamilyLink
  extend ActiveSupport::Concern

  include Editable

  class_methods do
    def restore_all(snapshots)
      snapshots.each { |snapshot| restore(snapshot) if Family.exists?(snapshot["family_id"]) }
    end
  end

  def edited_person = person

  private
    def edit_particulars
      { relatives: (family.partners + family.children).without(person).map(&:display_name).uniq }
    end
end
