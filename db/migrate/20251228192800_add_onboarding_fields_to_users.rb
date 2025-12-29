class AddOnboardingFieldsToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :favorite_sports, :jsonb, default: [], null: false
    add_column :users, :favorite_teams, :jsonb, default: [], null: false
    add_column :users, :onboarded, :boolean, default: false, null: false
  end
end
