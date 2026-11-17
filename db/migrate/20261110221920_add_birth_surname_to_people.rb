class AddBirthSurnameToPeople < ActiveRecord::Migration[8.1]
  def change
    add_column :people, :birth_surname, :string
  end
end
