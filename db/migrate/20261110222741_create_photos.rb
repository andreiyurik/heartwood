class CreatePhotos < ActiveRecord::Migration[8.1]
  def change
    create_table :photos do |t|
      t.references :person, null: false, foreign_key: true
      t.references :tree, null: false, foreign_key: true
      t.string :caption
      t.string :taken
      t.integer :taken_year

      t.timestamps
    end
  end
end
