class CreateDuplicateHints < ActiveRecord::Migration[8.1]
  def change
    create_table :duplicate_hints do |t|
      t.integer :tree_id,     null: false
      t.integer :person_a_id, null: false
      t.integer :person_b_id, null: false
      t.integer :score,       null: false
      t.json    :reasons
      t.string  :status, default: "pending", null: false
      t.timestamps
    end

    add_index :duplicate_hints, :tree_id
    add_index :duplicate_hints, [ :tree_id, :status ]
    add_index :duplicate_hints, [ :person_a_id, :person_b_id ]
    add_foreign_key :duplicate_hints, :trees
    add_foreign_key :duplicate_hints, :people, column: :person_a_id
    add_foreign_key :duplicate_hints, :people, column: :person_b_id
  end
end
