class CreatePeople < ActiveRecord::Migration[8.1]
  def change
    create_table :people do |t|
      t.string :given_names
      t.string :surname
      t.string :name_prefix
      t.string :name_suffix
      t.string :nickname
      t.string :sex, null: false, default: "U"
      t.string :gedcom_xref

      t.timestamps
    end
    add_index :people, :gedcom_xref
  end
end
