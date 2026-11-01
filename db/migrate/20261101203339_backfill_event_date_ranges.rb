class BackfillEventDateRanges < ActiveRecord::Migration[8.1]
  class Event < ActiveRecord::Base
    self.table_name = "events"
  end

  def up
    Event.where.not(date_raw: [ nil, "" ]).find_each do |event|
      date = FuzzyDate.parse(event.date_raw)
      event.update_columns(date_start: date&.start, date_end: date&.finish, date_precision: date&.precision)
    end
  end

  def down
  end
end
