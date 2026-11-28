# The form's "born" and "died" fields: free-text dates kept as the BIRT and DEAT events.
module Person::Lifespan
  extend ActiveSupport::Concern

  included do
    attr_writer :born, :died, :born_place, :deceased
    after_save :record_lifespan
  end

  def born = @born || birth&.date_label
  def died = @died || death&.date_label
  def born_place = @born_place || birth&.place_name

  # Died, the date unknown: without it a person with no birth year counts as living and is hidden from guests.
  def deceased
    @deceased.nil? ? (death.present? && death.date_raw.blank?) : ActiveModel::Type::Boolean.new.cast(@deceased)
  end

  private
    def record_lifespan
      dates = { "BIRT" => @born, "DEAT" => @died }.compact
      place, deceased = @born_place, (self.deceased unless @deceased.nil?)
      @born = @died = @born_place = @deceased = nil
      # A new person's own "added" entry already tells the story.
      previously_new_record? ? Edit.suppress { record_life(dates, place, deceased) } : record_life(dates, place, deceased)
    end

    def record_life(dates, place, deceased)
      dates.each { |kind, text| record_life_event(kind, text.to_s.strip) }
      record_birth_place(place) unless place.nil?
      record_death_without_date(deceased) unless deceased.nil?
    end

    def record_life_event(kind, text)
      if (event = events.find_by(kind: kind))
        event.update!(date_raw: text.presence) unless text.in?([ event.date_label.to_s, event.date_raw.to_s ])
      elsif text.present?
        events.create!(kind: kind, date_raw: text)
      end
    end

    def record_birth_place(name)
      if (event = events.find_by(kind: "BIRT"))
        event.update!(place_name: name) unless name.strip == event.place_name.to_s
      elsif name.present?
        events.create!(kind: "BIRT", place_name: name)
      end
    end

    def record_death_without_date(deceased)
      event = events.find_by(kind: "DEAT")
      if deceased
        events.create!(kind: "DEAT") unless event
      elsif event && event.date_raw.blank? && event.place.nil? && event.value.blank?
        event.destroy!
      end
    end
end
