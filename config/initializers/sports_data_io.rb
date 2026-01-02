# frozen_string_literal: true

# SportsDataIO NFL API Configuration
module SportsDataIO
  BASE_URL = "https://api.sportsdata.io/v3/nfl"

  ENDPOINTS = {
    scores:           "#{BASE_URL}/scores",
    stats:            "#{BASE_URL}/stats",
    pbp:              "#{BASE_URL}/pbp",
    odds:             "#{BASE_URL}/odds",
    projections:      "#{BASE_URL}/projections",
    advanced_metrics: "#{BASE_URL}/advanced-metrics",
    headshots:        "#{BASE_URL}/headshots",
    news_rotoballer:  "#{BASE_URL}/news-rotoballer",
    articles:         "#{BASE_URL}/articles-rotoballer",
    rotoworld:        "#{BASE_URL}/rotoworld"
  }.freeze
end

# Load SportsDataIO service files
Rails.application.config.to_prepare do
  require_dependency Rails.root.join('app/services/sports_data_io/endpoint_registry')
  require_dependency Rails.root.join('app/services/sports_data_io/cache_manager')
  require_dependency Rails.root.join('app/services/sports_data_io/base_client')
  require_dependency Rails.root.join('app/services/sports_data_io/context_service')
  require_dependency Rails.root.join('app/services/sports_data_io/query_router')
  require_dependency Rails.root.join('app/services/sports_data_io/builders/context_builder')
end
