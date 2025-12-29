# Assembles real-time context data for AI prompts
# Gathers user's teams, current games, news, and optionally market data
class ContextBuilder
  def initialize(user:, question:)
    @user = user
    @question = question
    @sports_service = SportsDataService.new
    @news_service = NewsService.new
    @odds_service = OddsApiService.new
  end

  # Build complete context hash for AI prompt injection
  def build
    {
      current_date: Date.current.strftime("%A, %B %d, %Y"),
      user_teams: user_teams_context,
      todays_games: todays_games_context,
      recent_results: recent_results_context,
      news: news_context,
      standings: standings_context,
      injuries: injuries_context,
      market_data: market_data_context
    }.compact
  end

  # Format context as text for system prompt injection
  def to_prompt_text
    context = build
    sections = []

    sections << "TODAY'S DATE: #{context[:current_date]}"

    if context[:user_teams].present?
      sections << format_user_teams(context[:user_teams])
    end

    if context[:todays_games].present?
      sections << format_todays_games(context[:todays_games])
    end

    if context[:recent_results].present?
      sections << format_recent_results(context[:recent_results])
    end

    if context[:news].present?
      sections << format_news(context[:news])
    end

    if context[:injuries].present?
      sections << format_injuries(context[:injuries])
    end

    if context[:market_data].present?
      sections << format_market_data(context[:market_data])
    end

    sections.join("\n\n")
  end

  private

  def team_ids
    @team_ids ||= @user.favorite_team_ids
  end

  def team_names
    @team_names ||= @user.favorite_team_names
  end

  def user_teams_context
    return nil if @user.favorite_teams.blank?

    @user.favorite_teams.map do |team|
      {
        sport: team["sport"],
        name: team["team_name"],
        id: team["team_id"]
      }
    end
  end

  def todays_games_context
    return nil if team_ids.blank?

    games = @sports_service.todays_games(team_ids)
    return nil if games.blank?

    games.map do |game|
      {
        matchup: game[:name],
        status: game[:status],
        detail: game[:status_detail],
        home: "#{game.dig(:home_team, :name)} #{game.dig(:home_team, :score) || ''}".strip,
        away: "#{game.dig(:away_team, :name)} #{game.dig(:away_team, :score) || ''}".strip,
        venue: game[:venue],
        broadcast: game[:broadcast]
      }
    end
  end

  def recent_results_context
    return nil if team_ids.blank?

    results = @sports_service.recent_results(team_ids, days: 7)
    return nil if results.blank?

    results.first(5).map do |game|
      home = game[:home_team]
      away = game[:away_team]

      {
        matchup: game[:name],
        result: "#{away[:name]} #{away[:score]} @ #{home[:name]} #{home[:score]}",
        winner: home[:winner] ? home[:name] : away[:name],
        date: game[:date]
      }
    end
  end

  def news_context
    return nil if @user.favorite_sports.blank?

    # Always fetch news for user's favorite sports
    # First try team-specific news, then fall back to general sport news
    headlines = @news_service.headlines(team_ids, limit: 5) if team_ids.present?
    headlines ||= []

    # If we didn't get enough team-specific news, add general sport news
    if headlines.length < 5
      general_news = @news_service.top_headlines(sports: @user.favorite_sports, limit: 5 - headlines.length)
      headlines.concat(general_news)
    end

    return nil if headlines.blank?

    headlines.first(5).map do |article|
      {
        headline: article[:headline],
        summary: article[:description],
        sport: article[:sport]
      }
    end
  end

  def standings_context
    return nil if @user.favorite_sports.blank?

    # Only include standings if question asks about them
    return nil unless question_about_standings?

    standings = {}
    @user.favorite_sports.each do |sport|
      sport_standings = @sports_service.standings(sport)
      next unless sport_standings

      # Filter to user's teams only
      user_team_standings = sport_standings.select do |s|
        team_ids.any? { |id| normalize_id(id, sport) == s[:team_id] }
      end

      standings[sport] = user_team_standings if user_team_standings.present?
    end

    standings.presence
  end

  def injuries_context
    return nil if team_ids.blank?

    # Only include injuries if question asks about them or mentions specific players
    return nil unless question_about_injuries?

    injuries = @sports_service.injuries(team_ids)
    return nil if injuries.blank?

    injuries.first(10).map do |injury|
      {
        player: injury[:player],
        position: injury[:position],
        status: injury[:status],
        injury: injury[:injury]
      }
    end
  end

  def market_data_context
    # Only include market data if question is betting-related
    return nil unless question_about_betting?

    odds_data = @odds_service.format_odds_for_ai
    return nil if odds_data.blank?

    odds_data
  end

  # Question analysis helpers
  def question_about_betting?
    betting_terms = %w[
      odds spread line bet betting moneyline over under total
      favorite underdog pick vegas book sportsbook wager market
      handicap parlay prop futures
    ]
    question_matches_terms?(betting_terms)
  end

  def question_about_standings?
    standings_terms = %w[
      standings record division conference playoff rank ranking
      first place seed position league table
    ]
    question_matches_terms?(standings_terms)
  end

  def question_about_injuries?
    injury_terms = %w[
      injury injured hurt out questionable doubtful
      probable health status playing available
    ]
    question_matches_terms?(injury_terms)
  end

  def question_matches_terms?(terms)
    q = @question.to_s.downcase
    terms.any? { |term| q.include?(term) }
  end

  def normalize_id(team_id, sport)
    case sport
    when "NBA" then team_id.to_s.sub("nba_", "")
    when "EPL", "MLS" then team_id.to_s.sub(/^(epl|mls)_/, "")
    else team_id.to_s
    end
  end

  # Formatting helpers for prompt text
  def format_user_teams(teams)
    team_list = teams.map { |t| "#{t[:name]} (#{t[:sport]})" }.join(", ")
    "USER'S FAVORITE TEAMS: #{team_list}"
  end

  def format_todays_games(games)
    lines = ["TODAY'S GAMES FOR USER'S TEAMS:"]
    games.each do |game|
      status = game[:status] == "Scheduled" ? game[:detail] : game[:status]
      lines << "- #{game[:matchup]} | #{status}"
      if game[:status] == "In Progress" || game[:status] == "Final"
        lines << "  Score: #{game[:away]} @ #{game[:home]}"
      end
    end
    lines.join("\n")
  end

  def format_recent_results(results)
    lines = ["RECENT RESULTS (Last 7 days):"]
    results.each do |game|
      lines << "- #{game[:result]} (#{game[:winner]} won)"
    end
    lines.join("\n")
  end

  def format_news(news)
    lines = ["RECENT NEWS:"]
    news.each do |article|
      lines << "- [#{article[:sport]}] #{article[:headline]}"
      lines << "  #{article[:summary]}" if article[:summary].present?
    end
    lines.join("\n")
  end

  def format_injuries(injuries)
    lines = ["INJURY REPORT:"]
    injuries.each do |injury|
      lines << "- #{injury[:player]} (#{injury[:position]}): #{injury[:status]} - #{injury[:injury]}"
    end
    lines.join("\n")
  end

  def format_market_data(odds_text)
    "MARKET DATA (for reference only):\n#{odds_text}"
  end
end
