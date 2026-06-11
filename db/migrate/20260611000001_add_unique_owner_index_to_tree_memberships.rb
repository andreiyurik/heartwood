class AddUniqueOwnerIndexToTreeMemberships < ActiveRecord::Migration[8.1]
  def change
    add_index :tree_memberships, :user_id,
              unique: true,
              where: "role = 'owner'",
              name: "index_tree_memberships_unique_owner_per_user"
  end
end
