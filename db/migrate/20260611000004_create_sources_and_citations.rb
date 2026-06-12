class CreateSourcesAndCitations < ActiveRecord::Migration[8.1]
  def change
    create_table :sources do |t|
      t.string :title, null: false
      t.string :url
      t.text   :citation_text
      t.references :tree, null: false, foreign_key: true
      t.timestamps
    end

    create_table :citations do |t|
      t.references :source,  null: false, foreign_key: true
      t.references :citable, polymorphic: true, null: false
      t.timestamps
    end
  end
end
