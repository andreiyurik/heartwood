class AddCrestToTrees < ActiveRecord::Migration[8.1]
  def change
    add_column :trees, :crest_shape, :string
    add_column :trees, :crest_hue, :integer
    add_column :trees, :crest_symbol, :string
  end
end
