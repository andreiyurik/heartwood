class CreateQuestions < ActiveRecord::Migration[8.1]
  def change
    create_table :questions do |t|
      t.references :tree, null: false, foreign_key: true
      t.references :person, null: false, foreign_key: true
      t.references :photo, foreign_key: true
      t.references :asker, foreign_key: { to_table: :users }
      t.text :body, null: false
      t.string :token, null: false, index: { unique: true }
      t.datetime :closed_at
      t.references :closed_by, foreign_key: { to_table: :users }
      t.timestamps
    end
  end
end
