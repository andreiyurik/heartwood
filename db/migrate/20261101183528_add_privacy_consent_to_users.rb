class AddPrivacyConsentToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :privacy_consented_at, :datetime
    add_column :users, :privacy_consent_version, :string
    change_column_null :edits, :user_id, true
  end
end
