# Fetches sports data from ESPN's unofficial API
# Provides scores, schedules, standings, and injuries for user's favorite teams
class SportsDataService
  BASE_URL = "site.api.espn.com"

  # ESPN sport/league mapping
  SPORT_ENDPOINTS = {
    "NFL" => "football/nfl",
    "NBA" => "basketball/nba",
    "MLB" => "baseball/mlb",
    "NHL" => "hockey/nhl",
    "EPL" => "soccer/eng.1",
    "MLS" => "soccer/usa.1"
  }.freeze

  CACHE_DURATION = 5.minutes

  # Get games for specific teams on a given date
  # Alias for todays_games with date support
  def games_for_teams(team_ids, date = Date.current, sport: nil)
    return [] if team_ids.blank?

    sports = sport ? [sport] : sports_for_team_ids(team_ids)
    games = []

    formatted_date = date.strftime("%Y%m%d")

    sports.each do |s|
      endpoint = SPORT_ENDPOINTS[s]
      next unless endpoint

      cache_key = "espn_scoreboard_#{s}_#{formatted_date}"
      scoreboard = Rails.cache.fetch(cache_key, expires_in: CACHE_DURATION) do
        fetch_scoreboard(endpoint, date: formatted_date)
      end

      next unless scoreboard

      # Filter to only games involving user's teams
      relevant_games = filter_games_by_teams(scoreboard, team_ids, s)

      # Format for view
      relevant_games.each do |game|
        games << {
          home: game[:home_team],
          away: game[:away_team],
          status: game[:status],
          time: game[:status_detail],
          venue: game[:venue]
        }
      end
    end

    games
  end

  # Get today's games for specific teams
  # Returns array of game hashes with scores, status, etc.
  def todays_games(team_ids, sport: nil)
    return [] if team_ids.blank?

    sports = sport ? [sport] : sports_for_team_ids(team_ids)
    games = []

    sports.each do |s|
      scoreboard = fetch_scoreboard_cached(s)
      next unless scoreboard

      # Filter to only games involving user's teams
      relevant_games = filter_games_by_teams(scoreboard, team_ids, s)
      games.concat(relevant_games)
    end

    games
  end

  # Get ALL today's games for a sport (no team filtering)
  def all_todays_games(sport)
    fetch_scoreboard_cached(sport) || []
  end

  def fetch_scoreboard_cached(sport)
    endpoint = SPORT_ENDPOINTS[sport]
    return nil unless endpoint

    cache_key = "espn_scoreboard_#{sport}_#{Date.current}_#{Time.current.hour}"
    Rails.cache.fetch(cache_key, expires_in: CACHE_DURATION) do
      fetch_scoreboard(endpoint)
    end
  end

  # Get recent results (last N days) for teams
  def recent_results(team_ids, days: 7, limit: 10)
    return [] if team_ids.blank?

    results = []
    sports = sports_for_team_ids(team_ids)

    sports.each do |sport|
      endpoint = SPORT_ENDPOINTS[sport]
      next unless endpoint

      # ESPN scoreboard with dates parameter for past games
      # Stop early if we have enough results
      (1..days).each do |day_offset|
        break if results.size >= limit

        date = (Date.current - day_offset).strftime("%Y%m%d")
        cache_key = "espn_scoreboard_#{sport}_#{date}"

        scoreboard = Rails.cache.fetch(cache_key, expires_in: 1.hour) do
          fetch_scoreboard(endpoint, date: date)
        end

        next unless scoreboard

        relevant_games = filter_games_by_teams(scoreboard, team_ids, sport)
        results.concat(relevant_games.select { |g| g[:status] == "Final" })
      end
    end

    results.sort_by { |g| g[:date] }.reverse.first(limit)
  end

  # Get standings for a sport
  def standings(sport)
    endpoint = SPORT_ENDPOINTS[sport]
    return nil unless endpoint

    cache_key = "espn_standings_#{sport}"
    Rails.cache.fetch(cache_key, expires_in: 30.minutes) do
      fetch_standings(endpoint)
    end
  end

  # Get injuries for teams (NFL/NBA primarily)
  def injuries(team_ids)
    return [] if team_ids.blank?

    all_injuries = []
    sports = sports_for_team_ids(team_ids)

    sports.each do |sport|
      next unless %w[NFL NBA].include?(sport) # Injuries mainly relevant for these

      endpoint = SPORT_ENDPOINTS[sport]
      next unless endpoint

      team_ids.each do |team_id|
        next unless team_id_for_sport?(team_id, sport)

        cache_key = "espn_injuries_#{sport}_#{team_id}"
        team_injuries = Rails.cache.fetch(cache_key, expires_in: 15.minutes) do
          fetch_team_injuries(endpoint, team_id)
        end

        all_injuries.concat(team_injuries) if team_injuries
      end
    end

    all_injuries
  end

  # Get team record/stats
  def team_record(team_id, sport)
    endpoint = SPORT_ENDPOINTS[sport]
    return nil unless endpoint

    espn_id = espn_team_id(team_id, sport)
    return nil unless espn_id

    cache_key = "espn_team_#{sport}_#{team_id}"
    Rails.cache.fetch(cache_key, expires_in: 15.minutes) do
      fetch_team_info(endpoint, espn_id)
    end
  end

  private

  def fetch_json(path)
    uri = URI("https://#{BASE_URL}#{path}")
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    http.open_timeout = 5
    http.read_timeout = 10

    request = Net::HTTP::Get.new(uri)
    request["User-Agent"] = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36"
    request["Accept"] = "application/json"

    response = http.request(request)

    if response.code == "200"
      JSON.parse(response.body)
    else
      Rails.logger.error("ESPN API error: #{response.code} for #{path}")
      nil
    end
  rescue StandardError => e
    Rails.logger.error("ESPN API error: #{e.message}")
    nil
  end

  def fetch_scoreboard(endpoint, date: nil)
    path = "/apis/site/v2/sports/#{endpoint}/scoreboard"
    path += "?dates=#{date}" if date

    data = fetch_json(path)
    return nil unless data && data["events"]

    data["events"].map { |event| parse_event(event) }.compact
  end

  def fetch_standings(endpoint)
    path = "/apis/site/v2/sports/#{endpoint}/standings"
    data = fetch_json(path)
    return nil unless data

    parse_standings(data)
  end

  def fetch_team_injuries(endpoint, team_id)
    espn_id = espn_team_id(team_id, sport_from_endpoint(endpoint))
    return [] unless espn_id

    path = "/apis/site/v2/sports/#{endpoint}/teams/#{espn_id}"
    data = fetch_json(path)
    return [] unless data

    parse_injuries(data)
  end

  def fetch_team_info(endpoint, espn_id)
    path = "/apis/site/v2/sports/#{endpoint}/teams/#{espn_id}"
    data = fetch_json(path)
    return nil unless data

    team = data.dig("team")
    return nil unless team

    {
      name: team["displayName"],
      record: team.dig("record", "items", 0, "summary"),
      standing: team.dig("standingSummary"),
      logo: team.dig("logos", 0, "href")
    }
  end

  def parse_event(event)
    competition = event["competitions"]&.first
    return nil unless competition

    home_team = competition["competitors"]&.find { |c| c["homeAway"] == "home" }
    away_team = competition["competitors"]&.find { |c| c["homeAway"] == "away" }

    {
      id: event["id"],
      name: event["name"],
      date: event["date"],
      status: parse_status(event.dig("status", "type", "name")),
      status_detail: event.dig("status", "type", "shortDetail"),
      home_team: parse_team(home_team),
      away_team: parse_team(away_team),
      venue: competition.dig("venue", "fullName"),
      broadcast: competition.dig("broadcasts", 0, "names")&.join(", ")
    }
  end

  def parse_team(team_data)
    return nil unless team_data

    abbr = team_data.dig("team", "abbreviation")
    {
      id: abbr&.downcase,
      name: team_data.dig("team", "displayName"),
      abbreviation: abbr,
      score: team_data["score"],
      winner: team_data["winner"],
      logo: team_data.dig("team", "logo"),
      record: team_data.dig("records", 0, "summary")
    }
  end

  def parse_status(status_name)
    case status_name
    when "STATUS_FINAL" then "Final"
    when "STATUS_IN_PROGRESS" then "In Progress"
    when "STATUS_SCHEDULED" then "Scheduled"
    when "STATUS_HALFTIME" then "Halftime"
    when "STATUS_POSTPONED" then "Postponed"
    else status_name
    end
  end

  def parse_standings(data)
    standings = []
    children = data.dig("children") || [data]

    children.each do |division|
      division_name = division.dig("name") || division.dig("abbreviation")
      entries = division.dig("standings", "entries") || []

      entries.each do |entry|
        team = entry.dig("team")
        stats = entry.dig("stats") || []

        wins = stats.find { |s| s["name"] == "wins" }&.dig("value") || 0
        losses = stats.find { |s| s["name"] == "losses" }&.dig("value") || 0

        standings << {
          division: division_name,
          team: team&.dig("displayName"),
          team_id: team&.dig("abbreviation")&.downcase,
          wins: wins.to_i,
          losses: losses.to_i,
          record: "#{wins.to_i}-#{losses.to_i}"
        }
      end
    end

    standings
  end

  def parse_injuries(data)
    injuries = data.dig("team", "injuries") || []

    injuries.map do |injury|
      {
        player: injury.dig("athlete", "displayName"),
        position: injury.dig("athlete", "position", "abbreviation"),
        status: injury["status"],
        injury: injury.dig("type", "description"),
        details: injury["details"]
      }
    end
  end

  def filter_games_by_teams(games, team_ids, sport)
    return [] unless games

    normalized_ids = team_ids.map { |id| normalize_team_id(id, sport) }

    games.compact.select do |game|
      home_id = game.dig(:home_team, :id)
      away_id = game.dig(:away_team, :id)
      normalized_ids.include?(home_id) || normalized_ids.include?(away_id)
    end
  end

  # Map our team_id format to ESPN abbreviation
  def normalize_team_id(team_id, sport)
    # Our IDs: "nyg" for NFL, "nba_ny" for NBA, "epl_ars" for EPL
    case sport
    when "NBA"
      team_id.to_s.sub("nba_", "")
    when "EPL", "MLS"
      team_id.to_s.sub(/^(epl|mls)_/, "")
    else
      team_id.to_s
    end
  end

  def espn_team_id(team_id, sport)
    normalize_team_id(team_id, sport)
  end

  def sports_for_team_ids(team_ids)
    sports = []
    team_ids.each do |id|
      if id.to_s.start_with?("nba_")
        sports << "NBA"
      elsif id.to_s.start_with?("epl_")
        sports << "EPL"
      elsif id.to_s.start_with?("mls_")
        sports << "MLS"
      else
        sports << "NFL" # Default to NFL for unprefixed IDs
      end
    end
    sports.uniq
  end

  def team_id_for_sport?(team_id, sport)
    case sport
    when "NBA" then team_id.to_s.start_with?("nba_")
    when "EPL" then team_id.to_s.start_with?("epl_")
    when "MLS" then team_id.to_s.start_with?("mls_")
    when "NFL" then !team_id.to_s.match?(/^(nba|epl|mls)_/)
    else false
    end
  end

  def sport_from_endpoint(endpoint)
    SPORT_ENDPOINTS.key(endpoint)
  end
end
