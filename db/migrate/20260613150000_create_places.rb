class CreatePlaces < ActiveRecord::Migration[8.1]
  def change
    create_table :places do |t|
      t.integer :tree_id, null: false
      t.string  :name,    null: false
      t.string  :gedcom_raw
      t.string  :country
      t.string  :region
      t.string  :city
      t.decimal :latitude,  precision: 10, scale: 7
      t.decimal :longitude, precision: 10, scale: 7
      t.timestamps
    end

    add_index :places, :tree_id
    add_foreign_key :places, :trees
  end
end
