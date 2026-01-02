# frozen_string_literal: true

# Fetches all data needed for NFL team dashboard using SportsDataIO
class TeamDashboardService
  def initialize(team)
    @team = team
    @client = SportsDataIO::BaseClient.new
    @context_service = SportsDataIO::ContextService.new
  end

  def build_dashboard
    return {} unless @team.sport == "NFL"

    base_context = @context_service.bootstrap
    season = base_context[:season]
    week = base_context[:week]
    team_key = @team.api_id.upcase

    {
      header: fetch_team_header(season, team_key),
      next_game: fetch_next_game(season, week, team_key),
      injuries: fetch_injuries(season, week, team_key),
      standings: fetch_standings(season, team_key),
      betting_record: fetch_betting_record(team_key),
      recent_results: fetch_recent_results(season, team_key),
      team_stats: fetch_team_stats(season, team_key),
      key_players: fetch_key_players(season, team_key),
      news: fetch_news(team_key)
    }
  rescue => e
    Rails.logger.error "Team dashboard error: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
    {}
  end

  private

  def fetch_team_header(season, team_key)
    standings = @client.get(:standings, { season: season })
    return nil unless standings.is_a?(Array)

    team_standing = standings.find { |s| s["Team"] == team_key }
    return nil unless team_standing

    {
      name: team_standing["Name"],
      wins: team_standing["Wins"],
      losses: team_standing["Losses"],
      ties: team_standing["Ties"] || 0,
      division: "#{team_standing['Conference']} #{team_standing['Division']}",
      division_rank: team_standing["DivisionRank"]
    }
  end

  def fetch_next_game(season, week, team_key)
    schedule = @client.get(:schedules, { season: season })
    return nil unless schedule.is_a?(Array)

    # Filter for upcoming games (not final and not bye week)
    next_game = schedule.find do |game|
      (game["HomeTeam"] == team_key || game["AwayTeam"] == team_key) &&
      game["Status"] != "Final" && game["Status"] != "F/OT" &&
      game["AwayTeam"] != "BYE" && game["HomeTeam"] != "BYE"
    end

    return nil unless next_game

    # Try to fetch odds for this game
    odds = fetch_game_odds(season, week, next_game["ScoreID"])

    # Get opponent key and look up full team info (api_id is stored lowercase)
    opponent_key = next_game["HomeTeam"] == team_key ? next_game["AwayTeam"] : next_game["HomeTeam"]
    opponent_team = Team.find_by(api_id: opponent_key.downcase, sport: "NFL")

    {
      opponent: opponent_key,
      opponent_name: opponent_team&.name || opponent_key,
      opponent_logo: opponent_team&.logo_url,
      is_home: next_game["HomeTeam"] == team_key,
      date: next_game["Date"] || next_game["DateTime"],
      channel: next_game["Channel"],
      spread: odds&.dig("HomePointSpread"),
      over_under: odds&.dig("OverUnder")
    }
  end

  def fetch_game_odds(season, week, score_id)
    odds_week = @client.get(:pregame_odds_week, { season: season, week: week })
    return nil unless odds_week.is_a?(Array)

    odds_week.find { |o| o["ScoreID"] == score_id }
  rescue
    nil
  end

  def fetch_injuries(season, week, team_key)
    injuries = @client.get(:injuries_by_team, { season: season, week: week, team: team_key })
    return [] unless injuries.is_a?(Array)

    injuries.map do |inj|
      {
        name: inj["Name"] || inj["PlayerName"],
        position: inj["Position"],
        status: inj["Status"] || inj["InjuryStatus"],
        body_part: inj["BodyPart"] || inj["Injury"]
      }
    end
  end

  def fetch_standings(season, team_key)
    standings = @client.get(:standings, { season: season })
    return [] unless standings.is_a?(Array)

    team_standing = standings.find { |s| s["Team"] == team_key }
    return [] unless team_standing

    division = "#{team_standing['Conference']} #{team_standing['Division']}"

    division_standings = standings.select do |s|
      "#{s['Conference']} #{s['Division']}" == division
    end.sort_by { |s| -s["Wins"] }

    division_standings.map.with_index(1) do |s, rank|
      {
        rank: rank,
        team: s["Team"],
        wins: s["Wins"],
        losses: s["Losses"],
        ties: s["Ties"] || 0,
        is_current: s["Team"] == team_key
      }
    end
  end

  def fetch_betting_record(team_key)
    # TeamTrends endpoint - note: may not be available in trial key
    {
      ats_wins: 0,
      ats_losses: 0,
      overs: 0,
      unders: 0
    }
  end

  def fetch_recent_results(season, team_key)
    # Get full season schedule and filter for completed games
    schedule = @client.get(:schedules, { season: season })
    return [] unless schedule.is_a?(Array)

    # Filter for this team's completed games
    team_games = schedule.select do |game|
      (game["HomeTeam"] == team_key || game["AwayTeam"] == team_key) &&
      (game["Status"] == "Final" || game["Status"] == "F/OT")
    end

    # Sort by week descending to get most recent first, then take last 5
    team_games = team_games.sort_by { |g| -(g["Week"] || 0) }.first(5)

    team_games.map do |game|
      is_home = game["HomeTeam"] == team_key
      home_score = game["HomeScore"] || 0
      away_score = game["AwayScore"] || 0
      won = is_home ? home_score > away_score : away_score > home_score

      {
        won: won,
        score: "#{game['AwayTeam']} #{away_score} @ #{game['HomeTeam']} #{home_score}",
        opponent: is_home ? game["AwayTeam"] : game["HomeTeam"],
        date: game["Date"] || game["DateTime"]
      }
    end
  end

  def fetch_team_stats(season, team_key)
    stats = @client.get(:team_season_stats, { season: season })
    return nil unless stats.is_a?(Array)

    team_stat = stats.find { |s| s["Team"] == team_key }
    return nil unless team_stat

    # Calculate PPG from Score and Games since PointsPerGame isn't provided
    games = team_stat["Games"] || 1
    points_per_game = team_stat["Score"].to_f / games
    points_allowed_per_game = team_stat["OpponentScore"].to_f / games
    total_yards = team_stat["OffensiveYards"] || 0

    # Add calculated PPG to all stats for ranking
    stats_with_ppg = stats.map do |s|
      g = s["Games"] || 1
      s.merge(
        "CalculatedPPG" => s["Score"].to_f / g,
        "CalculatedPAPG" => s["OpponentScore"].to_f / g
      )
    end

    # Calculate ranks
    points_rank = calculate_rank(stats_with_ppg, "CalculatedPPG", points_per_game, :desc)
    points_allowed_rank = calculate_rank(stats_with_ppg, "CalculatedPAPG", points_allowed_per_game, :asc)
    total_yards_rank = calculate_rank(stats, "OffensiveYards", total_yards, :desc)

    {
      points_per_game: points_per_game.round(1),
      points_allowed: team_stat["OpponentScore"],
      points_allowed_per_game: points_allowed_per_game.round(1),
      total_offense_yards: total_yards,
      total_defense_yards: team_stat["OpponentOffensiveYards"],
      points_rank: points_rank,
      points_allowed_rank: points_allowed_rank,
      offense_rank: total_yards_rank
    }
  end

  def calculate_rank(all_stats, field, value, direction)
    return nil unless value

    sorted = all_stats.map { |s| s[field] }.compact.sort
    sorted.reverse! if direction == :desc

    sorted.index(value) + 1 rescue nil
  end

  def fetch_key_players(season, team_key)
    # PlayerSeasonStatsByTeam endpoint
    {
      qb: { name: "N/A", yards: 0 },
      rb: { name: "N/A", yards: 0 },
      wr: { name: "N/A", yards: 0 }
    }
  end

  def fetch_news(team_key)
    news = @client.get(:news_by_team, { team: team_key })
    return [] unless news.is_a?(Array)

    news.first(3).map do |item|
      {
        title: item["Title"] || item["Headline"],
        updated: item["Updated"],
        source: item["Source"]
      }
    end
  end
end
