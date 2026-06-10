class CreateEvents < ActiveRecord::Migration[8.1]
  def change
    create_table :events do |t|
      t.references :eventable, polymorphic: true, null: false
      t.string :kind
      t.string :date_raw
      t.date :date_start
      t.date :date_end
      t.string :date_precision
      t.string :value

      t.timestamps
    end
  end
end
