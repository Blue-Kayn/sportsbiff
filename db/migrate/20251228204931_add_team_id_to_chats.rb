class AddTeamIdToChats < ActiveRecord::Migration[8.0]
  def change
    add_column :chats, :team_id, :string
    add_column :chats, :is_team_channel, :boolean, default: false, null: false
    add_index :chats, [:user_id, :team_id], unique: true, where: "team_id IS NOT NULL"
  end
end
