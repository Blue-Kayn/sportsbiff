class CreateTeams < ActiveRecord::Migration[8.0]
  def change
    create_table :teams do |t|
      t.string :name, null: false
      t.string :sport, null: false
      t.string :api_id, null: false
      t.jsonb :colors, default: {}
      t.string :logo_url

      t.timestamps
    end

    add_index :teams, :sport
    add_index :teams, :api_id, unique: true
    add_index :teams, [:sport, :name], unique: true
  end
end
