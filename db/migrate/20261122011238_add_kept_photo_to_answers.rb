class AddKeptPhotoToAnswers < ActiveRecord::Migration[8.1]
  def change
    add_reference :answers, :kept_photo, foreign_key: { to_table: :photos, on_delete: :nullify }
  end
end
