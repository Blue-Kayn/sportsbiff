class CreateOddsCaches < ActiveRecord::Migration[8.0]
  def change
    create_table :odds_caches do |t|
      t.string :sport
      t.string :event_id
      t.jsonb :data
      t.datetime :fetched_at

      t.timestamps
    end

    add_index :odds_caches, :sport
    add_index :odds_caches, :event_id
    add_index :odds_caches, [ :sport, :event_id ], unique: true
  end
end
