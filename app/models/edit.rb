class Edit < ApplicationRecord
  belongs_to :tree
  belongs_to :user
  belongs_to :subject, polymorphic: true, optional: true
  belongs_to :person, optional: true
  belongs_to :reverted_by, class_name: "User", optional: true

  enum :action, %w[ added edited removed ].index_by(&:itself)

  scope :sorted, -> { order(created_at: :desc, id: :desc) }

  def reverted? = reverted_at.present?

  def revertable?
    return false if reverted?
    removed? ? !subject_type.constantize.exists?(subject_id) : subject.present?
  end

  def revert(by:)
    return unless revertable?

    transaction do
      case action
      when "added"   then subject.destroy!
      when "edited"  then subject.update!(untouched_before_values)
      when "removed" then subject_type.constantize.restore(particulars["snapshot"])
      end
      update!(reverted_at: Time.current, reverted_by: by)
    end
  end

  private
    def untouched_before_values
      particulars["before"].select do |attribute, _|
        subject.public_send(attribute).as_json == particulars["after"][attribute]
      end
    end
end
