class CreateEdits < ActiveRecord::Migration[8.1]
  def change
    create_table :edits do |t|
      t.references :tree, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.references :subject, polymorphic: true, null: false
      t.integer :person_id, index: true
      t.string :action, null: false
      t.json :particulars, null: false, default: {}
      t.datetime :reverted_at
      t.references :reverted_by, foreign_key: { to_table: :users }
      t.timestamps
    end

    add_index :edits, %i[tree_id created_at]
  end
end
