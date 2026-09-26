class CreateImports < ActiveRecord::Migration[8.1]
  def change
    create_table :imports do |t|
      t.references :tree, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.string :status, null: false, default: "pending"
      t.integer :people_count, null: false, default: 0
      t.integer :families_count, null: false, default: 0
      t.json :warnings, null: false, default: []
      t.string :error

      t.timestamps
    end
  end
end
