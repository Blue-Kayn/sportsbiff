class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  has_many :chats, dependent: :destroy

  SUBSCRIPTION_TIERS = %w[free basic pro].freeze
  DAILY_LIMITS = { "free" => 10, "basic" => 50, "pro" => 500 }.freeze

  validates :subscription_tier, inclusion: { in: SUBSCRIPTION_TIERS }

  def daily_limit
    DAILY_LIMITS[subscription_tier] || DAILY_LIMITS["free"]
  end

  def can_query?
    reset_daily_count_if_needed
    daily_query_count < daily_limit
  end

  def increment_query_count!
    reset_daily_count_if_needed
    increment!(:daily_query_count)
  end

  def queries_remaining
    reset_daily_count_if_needed
    [ daily_limit - daily_query_count, 0 ].max
  end

  # Onboarding helpers
  def needs_onboarding?
    !onboarded?
  end

  def complete_onboarding!
    update!(onboarded: true)
  end

  # Favorite teams helpers
  def favorite_team_ids
    favorite_teams.map { |t| t["team_id"] }
  end

  def favorite_team_names
    favorite_teams.map { |t| t["team_name"] }
  end

  def teams_for_sport(sport)
    favorite_teams.select { |t| t["sport"] == sport }
  end

  def add_favorite_team(sport:, team_id:, team_name:)
    return if favorite_teams.any? { |t| t["team_id"] == team_id }

    self.favorite_teams = favorite_teams + [{ "sport" => sport, "team_id" => team_id, "team_name" => team_name }]
    save!
  end

  def remove_favorite_team(team_id)
    self.favorite_teams = favorite_teams.reject { |t| t["team_id"] == team_id }
    save!
  end

  private

  def reset_daily_count_if_needed
    if query_count_reset_date.nil? || query_count_reset_date < Date.current
      update(daily_query_count: 0, query_count_reset_date: Date.current)
    end
  end
end
