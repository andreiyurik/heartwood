# No migration ever created this table and no model used it; billing lives in the private engine.
class DropUnusedPayments < ActiveRecord::Migration[8.1]
  def up
    drop_table :payments, if_exists: true
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
