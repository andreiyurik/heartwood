class AddPlaceToEvents < ActiveRecord::Migration[8.1]
  def change
    add_column :events, :place_id, :integer
    add_index  :events, :place_id
  end
end
