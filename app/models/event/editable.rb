module Event::Editable
  extend ActiveSupport::Concern

  include ::Editable

  class_methods do
    def restore(snapshot)
      create!(snapshot.except("citations")).tap do |event|
        snapshot["citations"].each { |citation| event.citations.create!(citation.except("citable_type", "citable_id")) }
      end
    end
  end

  def snapshot
    super.merge("citations" => citations.map { |citation| citation.attributes.as_json })
  end

  def edited_person = (eventable if eventable.is_a?(Person))

  private
    def edit_particulars
      { kind: kind, family: (eventable.partners.map(&:display_name) if eventable.is_a?(Family)) }.compact
    end
end
