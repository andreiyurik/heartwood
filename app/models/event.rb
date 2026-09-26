class Event < ApplicationRecord
  include LiveUpdates

  KINDS = {
    "BIRT" => "Birth", "DEAT" => "Death", "BAPM" => "Baptism", "BURI" => "Burial",
    "MARR" => "Marriage", "DIV" => "Divorce",
    "OCCU" => "Occupation", "RESI" => "Residence", "EDUC" => "Education"
  }.freeze

  PERSON_KINDS = %w[BIRT DEAT BAPM BURI OCCU RESI EDUC].freeze

  belongs_to :tree, default: -> { eventable&.tree }
  belongs_to :eventable, polymorphic: true
  belongs_to :place, optional: true

  has_many :citations, as: :citable, dependent: :destroy
  has_many :sources,   through: :citations

  validates :kind, presence: true

  before_validation :assign_place

  def cite(source_attributes, citation_attributes = {})
    source = tree.sources.find_or_create_by!(title: source_attributes[:title].to_s.strip) do |new_source|
      new_source.assign_attributes(source_attributes.to_h.symbolize_keys.except(:title).compact_blank)
    end
    citations.create!(citation_attributes.to_h.merge(source: source))
  end

  def kind_label
    I18n.t("events.kinds.#{kind}", default: KINDS.fetch(kind, kind))
  end

  def best_citation_confidence
    order = Citation.confidences.keys
    citations.max_by { |c| order.index(c.confidence) }&.confidence
  end

  def summary
    date_raw.presence || value.presence
  end

  # Writing finds or creates a tree Place, so the same town typed twice is one row (and one map pin).
  def place_name = @place_name || place&.name

  def place_name=(value)
    @place_name = value.to_s.strip
  end

  attr_accessor :place_latitude, :place_longitude

  private

  def assign_place
    return if @place_name.nil?

    if @place_name.blank?
      self.place = nil
      return
    end

    # Places are shared by name across the tree: fill in coordinates only if missing,
    # so one event's pin never moves the others.
    found = tree.places.find_or_initialize_by(name: @place_name)
    if picked_coordinates? && !found.geocoded?
      found.latitude  = place_latitude
      found.longitude = place_longitude
    end
    found.save! if found.changed?

    self.place = found
  end

  def picked_coordinates?
    place_latitude.present? && place_longitude.present?
  end
end
