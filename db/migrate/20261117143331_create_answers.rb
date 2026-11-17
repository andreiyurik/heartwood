class CreateAnswers < ActiveRecord::Migration[8.1]
  def change
    create_table :answers do |t|
      t.references :question, null: false, foreign_key: true
      t.references :user, foreign_key: true
      t.string :author_name
      t.text :body, null: false
      t.datetime :accepted_at
      t.timestamps
    end
  end
end
