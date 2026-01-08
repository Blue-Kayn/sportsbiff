# frozen_string_literal: true

# Fetches team dashboard data using OpenAI web search with caching
# Replaces SportsDataIO API calls with real-time web search
class TeamDashboardWebService
  CACHE_TTL = 1.hour  # Cache for 1 hour to balance freshness vs API costs

  def initialize(team)
    @team = team
    @client = OpenAI::Client.new(
      access_token: Rails.application.credentials.dig(:openai_api_key) || ENV["OPENAI_API_KEY"]
    )
  end

  def build_dashboard
    return {} unless @team.sport == "NFL"

    cache_key = "team_dashboard/#{@team.api_id}/#{Date.current}"

    Rails.cache.fetch(cache_key, expires_in: CACHE_TTL) do
      Rails.logger.info("TeamDashboardWebService: Fetching fresh data for #{@team.name}")
      fetch_dashboard_via_web_search
    end
  rescue => e
    Rails.logger.error "TeamDashboardWebService error: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
    {}
  end

  private

  def fetch_dashboard_via_web_search
    team_name = @team.name
    team_key = @team.api_id.upcase

    # Build comprehensive query for web search
    query = build_dashboard_query(team_name)

    system_prompt = <<~PROMPT
      You are a sports data extraction assistant. Return ONLY valid JSON with no markdown formatting.
      Extract the following information about #{team_name} (#{team_key}) from current web sources.

      Return this exact JSON structure (use null for missing data, empty arrays [] for empty lists):

      {
        "header": {
          "name": "#{team_name}",
          "wins": <number>,
          "losses": <number>,
          "ties": <number>,
          "division": "<conference> <division>",
          "division_rank": <number>
        },
        "next_game": {
          "opponent": "<team abbreviation>",
          "opponent_name": "<full team name>",
          "is_home": <boolean>,
          "date": "<date string>",
          "channel": "<TV channel>",
          "spread": <number or null>,
          "over_under": <number or null>
        },
        "injuries": [
          {"name": "<player>", "position": "<pos>", "status": "<Out/Questionable/Doubtful>", "body_part": "<injury>"}
        ],
        "standings": [
          {"rank": 1, "team": "<abbrev>", "wins": <n>, "losses": <n>, "ties": <n>, "is_current": <boolean>}
        ],
        "betting_record": {
          "ats_wins": <number>,
          "ats_losses": <number>,
          "overs": <number>,
          "unders": <number>
        },
        "recent_results": [
          {"won": <boolean>, "score": "<away> <score> @ <home> <score>", "opponent": "<abbrev>", "date": "<date>"}
        ],
        "team_stats": {
          "points_per_game": <number>,
          "points_allowed_per_game": <number>,
          "total_offense_yards": <number>,
          "total_defense_yards": <number>,
          "points_rank": <1-32>,
          "points_allowed_rank": <1-32>,
          "offense_rank": <1-32>
        },
        "key_players": {
          "qb": {"name": "<name>", "yards": <passing yards>},
          "rb": {"name": "<name>", "yards": <rushing yards>},
          "wr": {"name": "<name>", "yards": <receiving yards>}
        },
        "news": [
          {"title": "<headline>", "updated": "<date>", "source": "<source>"}
        ]
      }

      IMPORTANT:
      - Return ONLY the JSON, no explanation or markdown
      - Use current 2024-2025 NFL season data
      - Include only top 3 injuries by importance
      - Include only last 5 games in recent_results
      - Include only top 3 news items
      - For standings, include only the team's division (4 teams)
    PROMPT

    api_messages = [
      { role: "system", content: system_prompt },
      { role: "user", content: query }
    ]

    response = @client.chat(
      parameters: {
        model: "gpt-4o-mini-search-preview",
        messages: api_messages,
        max_tokens: 2500,  # Higher limit for full JSON response
        web_search_options: {
          search_context_size: "medium"
        }
      }
    )

    content = response.dig("choices", 0, "message", "content")
    Rails.logger.info("TeamDashboardWebService: Got response with #{content&.length} chars")

    parse_dashboard_response(content)
  end

  def build_dashboard_query(team_name)
    <<~QUERY
      Get current #{team_name} NFL data:
      1. Current record (wins-losses-ties) and division standing
      2. Next upcoming game with opponent, date, TV channel, and betting odds (spread, over/under)
      3. Current injury report (key players, status)
      4. Full division standings
      5. Against-the-spread betting record this season
      6. Last 5 game results with scores
      7. Team statistics: points per game, points allowed, offensive/defensive yards, league rankings
      8. Top statistical leaders: QB passing yards, RB rushing yards, WR receiving yards
      9. Latest 3 news headlines about the team
    QUERY
  end

  def parse_dashboard_response(content)
    return {} if content.blank?

    # Try to extract JSON from the response
    # Sometimes the model wraps it in markdown code blocks
    json_content = content.gsub(/```json\n?/, "").gsub(/```\n?/, "").strip

    # Parse the JSON
    data = JSON.parse(json_content)

    # Transform to match expected format with symbol keys
    {
      header: symbolize_hash(data["header"]),
      next_game: symbolize_hash(data["next_game"]),
      injuries: (data["injuries"] || []).map { |i| symbolize_hash(i) },
      standings: (data["standings"] || []).map { |s| symbolize_hash(s) },
      betting_record: symbolize_hash(data["betting_record"]),
      recent_results: (data["recent_results"] || []).map { |r| symbolize_hash(r) },
      team_stats: symbolize_hash(data["team_stats"]),
      key_players: symbolize_key_players(data["key_players"]),
      news: (data["news"] || []).map { |n| symbolize_hash(n) }
    }
  rescue JSON::ParserError => e
    Rails.logger.error "TeamDashboardWebService JSON parse error: #{e.message}"
    Rails.logger.error "Content was: #{content}"
    {}
  end

  def symbolize_hash(hash)
    return nil if hash.nil?
    hash.transform_keys(&:to_sym)
  end

  def symbolize_key_players(data)
    return nil if data.nil?
    {
      qb: symbolize_hash(data["qb"]),
      rb: symbolize_hash(data["rb"]),
      wr: symbolize_hash(data["wr"])
    }
  end
end
