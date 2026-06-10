class CreateFamilyPartners < ActiveRecord::Migration[8.1]
  def change
    create_table :family_partners do |t|
      t.references :family, null: false, foreign_key: true
      t.references :person, null: false, foreign_key: true
      t.string :role

      t.timestamps
    end
  end
end
