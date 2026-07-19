class CreateTrees < ActiveRecord::Migration[8.1]
  def change
    create_table :trees do |t|
      t.string :name

      t.timestamps
    end
  end
end
