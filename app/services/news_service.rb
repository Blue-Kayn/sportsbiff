# Fetches sports news headlines from ESPN
# Provides team-specific news for user's favorite teams
class NewsService
  BASE_URL = "site.api.espn.com"

  SPORT_ENDPOINTS = {
    "NFL" => "football/nfl",
    "NBA" => "basketball/nba",
    "MLB" => "baseball/mlb",
    "NHL" => "hockey/nhl",
    "EPL" => "soccer/eng.1",
    "MLS" => "soccer/usa.1"
  }.freeze

  CACHE_DURATION = 15.minutes

  # Get headlines for specific teams
  # Returns array of news items sorted by recency
  def headlines(team_names_or_ids, limit: 5)
    return [] if team_names_or_ids.blank?

    all_news = []

    # Get general sports news and filter by team mentions
    sports = detect_sports(team_names_or_ids)

    sports.each do |sport|
      cache_key = "espn_news_#{sport}"
      news = Rails.cache.fetch(cache_key, expires_in: CACHE_DURATION) do
        fetch_sport_news(sport)
      end

      next unless news

      # Filter to news mentioning user's teams
      relevant_news = filter_news_by_teams(news, team_names_or_ids)
      all_news.concat(relevant_news)
    end

    # Also try team-specific news endpoints
    team_names_or_ids.each do |team_identifier|
      sport = sport_for_team(team_identifier)
      next unless sport

      cache_key = "espn_team_news_#{team_identifier}"
      team_news = Rails.cache.fetch(cache_key, expires_in: CACHE_DURATION) do
        fetch_team_news(team_identifier, sport)
      end

      all_news.concat(team_news) if team_news
    end

    # Deduplicate by headline and sort by date
    all_news
      .uniq { |n| n[:headline] }
      .sort_by { |n| n[:published_at] || Time.current }
      .reverse
      .first(limit)
  end

  # Get news specifically about a team (filters sport news by team name)
  def team_news(team, limit: 10)
    return [] unless team

    sport = team.sport
    team_name = team.name
    # Get variations of team name for matching
    # e.g., "Arizona Cardinals" -> ["Arizona Cardinals", "Cardinals", "ARI"]
    name_parts = team_name.split
    search_terms = [
      team_name.downcase,                    # "arizona cardinals"
      name_parts.last&.downcase,             # "cardinals"
      team.api_id.upcase,                    # "ARI"
      name_parts.first&.downcase             # "arizona" (for city-based references)
    ].compact.uniq

    # Fetch sport news
    cache_key = "espn_news_#{sport}"
    all_news = Rails.cache.fetch(cache_key, expires_in: CACHE_DURATION) do
      fetch_sport_news(sport)
    end || []

    # Filter to news mentioning this team
    team_specific = all_news.select do |article|
      text = "#{article[:headline]} #{article[:description]}".downcase
      search_terms.any? { |term| text.include?(term) }
    end

    # Also try to fetch from team-specific endpoint
    team_endpoint_news = fetch_team_news(team.api_id, sport) || []
    team_specific.concat(team_endpoint_news)

    # Deduplicate and sort
    team_specific
      .uniq { |n| n[:headline] }
      .sort_by { |n| n[:published_at] || Time.current }
      .reverse
      .first(limit)
  end

  # Get top headlines across all sports (for general feed)
  def top_headlines(sports: nil, limit: 10)
    sports ||= SPORT_ENDPOINTS.keys
    all_news = []

    sports.each do |sport|
      cache_key = "espn_news_#{sport}"
      news = Rails.cache.fetch(cache_key, expires_in: CACHE_DURATION) do
        fetch_sport_news(sport)
      end

      all_news.concat(news) if news
    end

    all_news
      .sort_by { |n| n[:published_at] || Time.current }
      .reverse
      .first(limit)
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
      Rails.logger.error("ESPN News API error: #{response.code} for #{path}")
      nil
    end
  rescue StandardError => e
    Rails.logger.error("ESPN News API error: #{e.message}")
    nil
  end

  def fetch_sport_news(sport)
    endpoint = SPORT_ENDPOINTS[sport]
    return [] unless endpoint

    path = "/apis/site/v2/sports/#{endpoint}/news"
    data = fetch_json(path)
    return [] unless data

    articles = data["articles"] || []
    articles.map { |article| parse_article(article, sport) }
  end

  def fetch_team_news(team_identifier, sport)
    endpoint = SPORT_ENDPOINTS[sport]
    return [] unless endpoint

    # Try to get team-specific news
    team_abbr = normalize_team_id(team_identifier, sport)

    # ESPN team news endpoint
    path = "/apis/site/v2/sports/#{endpoint}/teams/#{team_abbr}/news"
    data = fetch_json(path)
    return [] unless data

    articles = data["articles"] || []
    articles.map { |article| parse_article(article, sport) }
  end

  def parse_article(article, sport)
    {
      headline: article["headline"],
      description: article["description"],
      link: article.dig("links", "web", "href") || article.dig("links", "api", "news", "href"),
      image: article.dig("images", 0, "url"),
      published_at: parse_date(article["published"]),
      sport: sport,
      source: "ESPN"
    }
  end

  def parse_date(date_string)
    return nil unless date_string
    Time.parse(date_string)
  rescue ArgumentError
    nil
  end

  def filter_news_by_teams(news, team_identifiers)
    return news if team_identifiers.blank?

    # Build list of team names to search for
    team_names = team_identifiers.map do |id|
      team = Team.find_by(api_id: id)
      team ? [team.name, team.name.split.last] : [id] # Include short name like "Giants"
    end.flatten.compact.uniq

    news.select do |article|
      headline = article[:headline].to_s.downcase
      description = article[:description].to_s.downcase
      text = "#{headline} #{description}"

      team_names.any? { |name| text.include?(name.downcase) }
    end
  end

  def detect_sports(team_identifiers)
    sports = []
    team_identifiers.each do |id|
      if id.to_s.start_with?("nba_")
        sports << "NBA"
      elsif id.to_s.start_with?("epl_")
        sports << "EPL"
      elsif id.to_s.start_with?("mls_")
        sports << "MLS"
      else
        sports << "NFL"
      end
    end
    sports.uniq
  end

  def sport_for_team(team_identifier)
    case team_identifier.to_s
    when /^nba_/ then "NBA"
    when /^epl_/ then "EPL"
    when /^mls_/ then "MLS"
    else "NFL"
    end
  end

  def normalize_team_id(team_id, sport)
    case sport
    when "NBA"
      team_id.to_s.sub("nba_", "")
    when "EPL", "MLS"
      team_id.to_s.sub(/^(epl|mls)_/, "")
    else
      team_id.to_s
    end
  end
end
