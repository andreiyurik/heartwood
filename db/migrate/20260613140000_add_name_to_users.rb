class AddNameToUsers < ActiveRecord::Migration[8.1]
  def change
    # Nullable at the DB level so existing rows survive; presence is enforced in the
    # User model for all new sign-ups. The name is used to greet people personally
    # (welcome email, UI) — the account holder, distinct from a Person in the tree.
    add_column :users, :name, :string
  end
end
