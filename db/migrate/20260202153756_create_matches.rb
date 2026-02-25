class CreateMatches < ActiveRecord::Migration[7.1]
  def change
    create_table :matches do |t|
      t.references :user_a, null: false, foreign_key: { to_table: :users }
      t.references :user_b, null: false, foreign_key: { to_table: :users }
      t.float :score
      t.integer :status
      t.jsonb :overlap_windows_json, default: {}

      t.timestamps
    end

    add_index :matches, %i[user_a_id user_b_id], unique: true
  end
end
