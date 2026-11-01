class CreateArchives < ActiveRecord::Migration[8.1]
  def change
    create_table :archives do |t|
      t.references :tree, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.string :status, null: false, default: "pending"
      t.timestamps
    end
  end
end
