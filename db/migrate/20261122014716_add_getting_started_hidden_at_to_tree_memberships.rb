class AddGettingStartedHiddenAtToTreeMemberships < ActiveRecord::Migration[8.1]
  def change
    add_column :tree_memberships, :getting_started_hidden_at, :datetime
  end
end
