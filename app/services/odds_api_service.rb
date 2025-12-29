class OddsApiService
  BASE_URL = "https://api.the-odds-api.com/v4"
  DEFAULT_REGIONS = "us"
  DEFAULT_MARKETS = "h2h,spreads,totals"

  def initialize(sport: "americanfootball_nfl")
    @sport = sport
    @api_key = Rails.application.credentials.dig(:odds_api_key) || ENV["ODDS_API_KEY"]
  end

  def fetch_upcoming_events
    return mock_events if @api_key.blank?

    url = "#{BASE_URL}/sports/#{@sport}/odds"
    response = Faraday.get(url) do |req|
      req.params["apiKey"] = @api_key
      req.params["regions"] = DEFAULT_REGIONS
      req.params["markets"] = DEFAULT_MARKETS
      req.params["oddsFormat"] = "american"
    end

    return nil unless response.success?

    JSON.parse(response.body)
  rescue Faraday::Error => e
    Rails.logger.error("OddsApiService error: #{e.message}")
    nil
  end

  def fetch_event(event_id)
    cached = OddsCache.get_or_fetch(sport: @sport, event_id: event_id)
    return cached if cached

    events = fetch_upcoming_events
    return nil unless events

    events.find { |e| e["id"] == event_id }
  end

  def format_odds_for_ai
    events = fetch_upcoming_events
    return "No current odds data available." if events.nil? || events.empty?

    formatted = events.map { |event| format_event(event) }
    formatted.join("\n\n")
  end

  private

  def connection
    @connection ||= Faraday.new(url: BASE_URL) do |f|
      f.request :json
      f.response :raise_error
      f.adapter Faraday.default_adapter
    end
  end

  def format_event(event)
    home = event["home_team"]
    away = event["away_team"]
    time = Time.parse(event["commence_time"]).strftime("%a %b %d, %I:%M %p")

    lines = [ "#{away} @ #{home} - #{time}" ]

    # Collect all moneyline odds for the favorite, then rank by best value
    ml_odds = []
    spread_odds = []
    total_odds = []

    event["bookmakers"]&.each do |book|
      book_name = book["title"]
      book["markets"]&.each do |market|
        case market["key"]
        when "h2h"
          market["outcomes"].each do |o|
            ml_odds << { book: book_name, team: o["name"], price: o["price"] }
          end
        when "spreads"
          market["outcomes"].each do |o|
            spread_odds << { book: book_name, team: o["name"], point: o["point"], price: o["price"] }
          end
        when "totals"
          market["outcomes"].each do |o|
            total_odds << { book: book_name, type: o["name"], point: o["point"], price: o["price"] }
          end
        end
      end
    end

    # Group by team and sort by best odds (highest price = best value)
    lines << "  MONEYLINE (ranked by best odds):"
    ml_by_team = ml_odds.group_by { |o| o[:team] }
    ml_by_team.each do |team, odds|
      sorted = odds.sort_by { |o| -o[:price] }.first(10)
      sorted.each_with_index do |o, i|
        marker = i == 0 ? " ← Best" : ""
        lines << "    #{i + 1}. #{team} #{format_american_odds(o[:price])} (#{o[:book]})#{marker}"
      end
    end

    # Spreads - group by team and sort
    if spread_odds.any?
      lines << "  SPREAD (ranked by best odds):"
      spread_by_team = spread_odds.group_by { |o| o[:team] }
      spread_by_team.each do |team, odds|
        sorted = odds.sort_by { |o| -o[:price] }.first(10)
        sorted.each_with_index do |o, i|
          marker = i == 0 ? " ← Best" : ""
          lines << "    #{i + 1}. #{team} #{o[:point]} (#{format_american_odds(o[:price])}) (#{o[:book]})#{marker}"
        end
      end
    end

    # Totals - group by over/under
    if total_odds.any?
      lines << "  TOTAL (ranked by best odds):"
      total_by_type = total_odds.group_by { |o| o[:type] }
      total_by_type.each do |type, odds|
        sorted = odds.sort_by { |o| -o[:price] }.first(10)
        sorted.each_with_index do |o, i|
          marker = i == 0 ? " ← Best" : ""
          lines << "    #{i + 1}. #{type} #{o[:point]} (#{format_american_odds(o[:price])}) (#{o[:book]})#{marker}"
        end
      end
    end

    lines.join("\n")
  end

  def format_american_odds(odds)
    # Handle both decimal and American odds formats
    if odds.is_a?(Float) && odds > 0 && odds < 100
      # Decimal odds - convert to American
      if odds >= 2.0
        american = ((odds - 1) * 100).round
        "+#{american}"
      else
        american = (-100 / (odds - 1)).round
        american.to_s
      end
    else
      # Already American format
      odds.positive? ? "+#{odds.to_i}" : odds.to_i.to_s
    end
  end

  def mock_events
    # Mock data for development without API key
    [
      {
        "id" => "mock_1",
        "sport_key" => @sport,
        "commence_time" => (Time.current + 2.days).iso8601,
        "home_team" => "Kansas City Chiefs",
        "away_team" => "Las Vegas Raiders",
        "bookmakers" => [
          {
            "title" => "DraftKings",
            "markets" => [
              {
                "key" => "h2h",
                "outcomes" => [
                  { "name" => "Kansas City Chiefs", "price" => -280 },
                  { "name" => "Las Vegas Raiders", "price" => 230 }
                ]
              },
              {
                "key" => "spreads",
                "outcomes" => [
                  { "name" => "Kansas City Chiefs", "price" => -110, "point" => -6.5 },
                  { "name" => "Las Vegas Raiders", "price" => -110, "point" => 6.5 }
                ]
              },
              {
                "key" => "totals",
                "outcomes" => [
                  { "name" => "Over", "price" => -110, "point" => 47.5 },
                  { "name" => "Under", "price" => -110, "point" => 47.5 }
                ]
              }
            ]
          }
        ]
      },
      {
        "id" => "mock_2",
        "sport_key" => @sport,
        "commence_time" => (Time.current + 3.days).iso8601,
        "home_team" => "Buffalo Bills",
        "away_team" => "Miami Dolphins",
        "bookmakers" => [
          {
            "title" => "FanDuel",
            "markets" => [
              {
                "key" => "h2h",
                "outcomes" => [
                  { "name" => "Buffalo Bills", "price" => -175 },
                  { "name" => "Miami Dolphins", "price" => 150 }
                ]
              },
              {
                "key" => "spreads",
                "outcomes" => [
                  { "name" => "Buffalo Bills", "price" => -110, "point" => -3.5 },
                  { "name" => "Miami Dolphins", "price" => -110, "point" => 3.5 }
                ]
              },
              {
                "key" => "totals",
                "outcomes" => [
                  { "name" => "Over", "price" => -105, "point" => 52.5 },
                  { "name" => "Under", "price" => -115, "point" => 52.5 }
                ]
              }
            ]
          }
        ]
      }
    ]
  end
end
