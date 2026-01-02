# frozen_string_literal: true

module SportsDataIO
  class ContextService
    def initialize
      @client = BaseClient.new
    end

    # Call this once per session to get temporal context
    def bootstrap
      {
        season: current_season,
        week: current_week,
        games_in_progress: games_in_progress?,
        teams: active_teams_lookup
      }
    rescue => e
      Rails.logger.error "SportsDataIO bootstrap error: #{e.message}"
      # Return defaults if API fails
      {
        season: 2024,
        week: 18,
        games_in_progress: false,
        teams: {}
      }
    end

    def current_season
      # API returns year for the season (e.g., 2025 for 2025-2026 season)
      # Just append REG for regular season
      year = @client.get(:current_season)
      "#{year}REG"
    end

    def current_week
      @client.get(:current_week)
    end

    def upcoming_week
      @client.get(:upcoming_week)
    end

    def games_in_progress?
      @client.get(:are_games_in_progress) || false
    end

    def active_teams_lookup
      teams = @client.get(:teams_active) || []
      teams.index_by { |t| t["Key"] }
    rescue => e
      Rails.logger.error "Failed to fetch teams: #{e.message}"
      {}
    end
  end
end
