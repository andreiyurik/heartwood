class ChangeDefaultRoleOnTreeMemberships < ActiveRecord::Migration[8.1]
  def change
    # The DB default mirrored the model's, so a membership created without an
    # explicit role silently became an owner. Least-privileged default instead.
    change_column_default :tree_memberships, :role, from: "owner", to: "viewer"
  end
end
