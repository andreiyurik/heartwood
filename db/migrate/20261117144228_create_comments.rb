class CreateComments < ActiveRecord::Migration[8.1]
  def change
    create_table :comments do |t|
      t.references :tree, null: false, foreign_key: true
      t.references :person, null: false, foreign_key: true
      t.references :user, foreign_key: true
      t.text :body, null: false
      t.timestamps
    end
  end
end
