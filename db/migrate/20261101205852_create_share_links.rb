class CreateShareLinks < ActiveRecord::Migration[8.1]
  def change
    create_table :share_links do |t|
      t.references :tree, null: false, foreign_key: true, index: { unique: true }
      t.string :token, null: false, index: { unique: true }
      t.timestamps
    end
  end
end
