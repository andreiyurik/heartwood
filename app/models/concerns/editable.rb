module Editable
  extend ActiveSupport::Concern

  UNTRACKED_ATTRIBUTES = %w[ created_at updated_at ].freeze

  included do
    has_many :edits, as: :subject

    after_create  { record_edit :added }
    after_update  { record_edit :edited, **saved_attribute_changes if saved_attribute_changes.any? }
    before_destroy(prepend: true) { @snapshot = snapshot }
    after_destroy { record_edit :removed, snapshot: @snapshot unless destroyed_by_association }
  end

  class_methods do
    def restore(snapshot)
      create!(snapshot)
    end
  end

  def snapshot = attributes.as_json

  def edited_person = nil

  private
    def record_edit(action, **particulars)
      # Only a person's own edits are history; imports and background jobs are not.
      return unless Current.user

      Edit.create! tree: tree, user: Current.user, subject: self, person_id: edited_person&.id,
        action: action, particulars: { name: edited_person&.display_name, **edit_particulars, **particulars }
    end

    def edit_particulars = {}

    def saved_attribute_changes
      changes = saved_changes.except(*UNTRACKED_ATTRIBUTES)
      changes.any? ? { before: changes.transform_values(&:first).as_json, after: changes.transform_values(&:last).as_json } : {}
    end
end
