class AddPilotUpdatesToUsers < ActiveRecord::Migration[7.1]
  def change
    add_column :users, :pilot_updates, :boolean, default: false, null: false
  end
end
