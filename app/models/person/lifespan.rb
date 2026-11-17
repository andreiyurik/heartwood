# The form's "born" and "died" fields: free-text dates kept as the BIRT and DEAT events.
module Person::Lifespan
  extend ActiveSupport::Concern

  included do
    attr_writer :born, :died
    after_save :record_lifespan
  end

  def born = @born || birth&.date_label
  def died = @died || death&.date_label

  private
    def record_lifespan
      dates = { "BIRT" => @born, "DEAT" => @died }.compact
      @born = @died = nil
      # A new person's own "added" entry already tells the story.
      previously_new_record? ? Edit.suppress { record_life_events(dates) } : record_life_events(dates)
    end

    def record_life_events(dates)
      dates.each { |kind, text| record_life_event(kind, text.to_s.strip) }
    end

    def record_life_event(kind, text)
      if (event = events.find_by(kind: kind))
        event.update!(date_raw: text.presence) unless text.in?([ event.date_label.to_s, event.date_raw.to_s ])
      elsif text.present?
        events.create!(kind: kind, date_raw: text)
      end
    end
end
