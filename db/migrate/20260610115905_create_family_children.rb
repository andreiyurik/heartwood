class CreateFamilyChildren < ActiveRecord::Migration[8.1]
  def change
    create_table :family_children do |t|
      t.references :family, null: false, foreign_key: true
      t.references :person, null: false, foreign_key: true
      t.string :pedigree
      t.integer :position

      t.timestamps
    end
  end
end
