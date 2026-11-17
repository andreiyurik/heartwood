class AddDigestToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :weekly_digest, :boolean, default: true, null: false
    add_column :users, :locale, :string
  end
end
