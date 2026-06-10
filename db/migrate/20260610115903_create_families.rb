class CreateFamilies < ActiveRecord::Migration[8.1]
  def change
    create_table :families do |t|
      t.string :gedcom_xref

      t.timestamps
    end
  end
end
