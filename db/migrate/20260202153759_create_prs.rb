class CreatePrs < ActiveRecord::Migration[7.1]
  def change
    create_table :prs do |t|
      t.references :user, null: false, foreign_key: true
      t.string :exercise
      t.decimal :value
      t.string :unit
      t.date :date

      t.timestamps
    end
  end
end
