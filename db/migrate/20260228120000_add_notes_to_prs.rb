class AddNotesToPrs < ActiveRecord::Migration[7.1]
  def change
    add_column :prs, :notes, :text
  end
end
