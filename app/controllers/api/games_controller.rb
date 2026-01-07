module Api
  class GamesController < BaseController
    # GET /api/games/today?sport=nfl
    def today
      sport = params[:sport].to_s.downcase
      games = fetch_todays_games(sport)
      render_json(games)
    end

    private

    def fetch_todays_games(sport)
      case sport
      when "nfl"
        fetch_nfl_games
      else
        []
      end
    end

    def fetch_nfl_games
      # Try to get real games from SportsDataIO
      begin
        service = SportsDataService.new
        games = service.nfl_games_this_week

        if games.present?
          games.map do |game|
            away = game["AwayTeam"] || "TBD"
            home = game["HomeTeam"] || "TBD"
            {
              id: game["GameKey"] || game["GlobalGameID"],
              away_team: away,
              home_team: home,
              display: "#{away} @ #{home}",
              date: game["Date"] || game["Day"],
              status: game["Status"]
            }
          end
        else
          # Fallback to placeholder if no games from API
          placeholder_games
        end
      rescue StandardError => e
        Rails.logger.error("Failed to fetch NFL games: #{e.message}")
        placeholder_games
      end
    end

    def placeholder_games
      # Return placeholder when API is unavailable
      # These serve as examples for the menu interface
      [
        { id: "placeholder-1", away_team: "KC", home_team: "BUF", display: "Chiefs @ Bills", status: "Scheduled" },
        { id: "placeholder-2", away_team: "DAL", home_team: "PHI", display: "Cowboys @ Eagles", status: "Scheduled" },
        { id: "placeholder-3", away_team: "SF", home_team: "SEA", display: "49ers @ Seahawks", status: "Scheduled" }
      ]
    end
  end
end
