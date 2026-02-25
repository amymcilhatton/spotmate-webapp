class CreateMatchDecisions < ActiveRecord::Migration[7.1]
  def change
    create_table :match_decisions do |t|
      t.references :match, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.integer :decision, null: false
      t.text :note

      t.timestamps
    end
  end
end
