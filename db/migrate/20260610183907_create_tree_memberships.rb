class CreateTreeMemberships < ActiveRecord::Migration[8.1]
  def change
    create_table :tree_memberships do |t|
      t.references :tree, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.string :role, default: "owner", null: false

      t.timestamps
    end

    add_index :tree_memberships, %i[tree_id user_id], unique: true
  end
end
