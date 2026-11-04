class DropUnusedPayments < ActiveRecord::Migration[8.1]
  def up
    drop_table :payments, if_exists: true
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
