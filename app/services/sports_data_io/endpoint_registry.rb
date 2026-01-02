# frozen_string_literal: true

module SportsDataIO
  class EndpointRegistry
    # Utility Endpoints - Bootstrap temporal context
    UTILITY_ENDPOINTS = {
      current_season:      { path: "/json/CurrentSeason",      ttl: 5.minutes,  base: :scores },
      current_week:        { path: "/json/CurrentWeek",        ttl: 5.minutes,  base: :scores },
      upcoming_season:     { path: "/json/UpcomingSeason",     ttl: 5.minutes,  base: :scores },
      upcoming_week:       { path: "/json/UpcomingWeek",       ttl: 5.minutes,  base: :scores },
      last_completed_week: { path: "/json/LastCompletedWeek",  ttl: 5.minutes,  base: :scores },
      timeframes:          { path: "/json/Timeframes/{type}",  ttl: 3.minutes,  base: :scores },
      are_games_in_progress: { path: "/json/AreAnyGamesInProgress", ttl: 5.seconds, base: :scores },
      bye_weeks:           { path: "/json/Byes/{season}",      ttl: 15.minutes, base: :scores }
    }.freeze

    # Reference Data - Static/semi-static
    REFERENCE_ENDPOINTS = {
      teams_active:        { path: "/json/Teams",              ttl: 4.hours,   base: :scores },
      teams_all:           { path: "/json/AllTeams",           ttl: 4.hours,   base: :scores },
      teams_basic:         { path: "/json/TeamsBasic",         ttl: 5.minutes, base: :scores },
      stadiums:            { path: "/json/Stadiums",           ttl: 4.hours,   base: :scores }
    }.freeze

    # Player Endpoints
    PLAYER_ENDPOINTS = {
      players_all:         { path: "/json/Players",            ttl: 1.hour,    base: :scores },
      players_by_team:     { path: "/json/Players/{team}",     ttl: 1.hour,    base: :scores },
      depth_charts_active: { path: "/json/DepthCharts",        ttl: 5.minutes, base: :scores },
      injuries_all:        { path: "/json/Injuries/{season}/{week}", ttl: 5.minutes, base: :stats },
      injuries_by_team:    { path: "/json/Injuries/{season}/{week}/{team}", ttl: 5.minutes, base: :stats }
    }.freeze

    # Schedule & Scores
    SCHEDULE_SCORE_ENDPOINTS = {
      schedules:           { path: "/json/Schedules/{season}", ttl: 3.minutes, base: :scores },
      schedules_basic:     { path: "/json/SchedulesBasic/{season}", ttl: 3.minutes, base: :scores },
      standings:           { path: "/json/Standings/{season}", ttl: 5.minutes, base: :scores },
      scores_by_week:      { path: "/json/ScoresByWeek/{season}/{week}", ttl: 5.seconds, base: :scores },
      scores_by_date:      { path: "/json/ScoresByDate/{date}", ttl: 5.seconds, base: :scores },
      scores_basic:        { path: "/json/ScoresBasic/{season}/{week}", ttl: 5.seconds, base: :scores }
    }.freeze

    # Statistics
    STATS_ENDPOINTS = {
      team_game_stats:     { path: "/json/TeamGameStats/{season}/{week}", ttl: 5.minutes, base: :scores },
      team_season_stats:   { path: "/json/TeamSeasonStats/{season}", ttl: 5.minutes, base: :scores },
      player_game_stats_week: { path: "/json/PlayerGameStatsByWeek/{season}/{week}", ttl: 5.minutes, base: :stats },
      player_season_stats: { path: "/json/PlayerSeasonStats/{season}", ttl: 15.minutes, base: :stats }
    }.freeze

    # Box Scores
    BOX_SCORE_ENDPOINTS = {
      box_score_v3:        { path: "/json/BoxScoreByScoreIDV3/{scoreid}", ttl: 1.minute, base: :stats },
      box_scores_delta:    { path: "/json/BoxScoresDeltaV3/{season}/{week}/{playerstoinclude}/{minutes}", ttl: 3.seconds, base: :stats }
    }.freeze

    # Betting/Odds
    ODDS_ENDPOINTS = {
      pregame_odds_week:   { path: "/json/GameOddsByWeek/{season}/{week}", ttl: 30.seconds, base: :odds },
      live_odds_week:      { path: "/json/LiveGameOddsByWeek/{season}/{week}", ttl: 5.seconds, base: :odds }
    }.freeze

    # News
    NEWS_ENDPOINTS = {
      news:                { path: "/json/News", ttl: 3.minutes, base: :scores },
      news_by_date:        { path: "/json/NewsByDate/{date}", ttl: 3.minutes, base: :scores },
      news_by_team:        { path: "/json/NewsByTeam/{team}", ttl: 3.minutes, base: :scores }
    }.freeze

    # Combine all endpoints
    ALL_ENDPOINTS = UTILITY_ENDPOINTS
      .merge(REFERENCE_ENDPOINTS)
      .merge(PLAYER_ENDPOINTS)
      .merge(SCHEDULE_SCORE_ENDPOINTS)
      .merge(STATS_ENDPOINTS)
      .merge(BOX_SCORE_ENDPOINTS)
      .merge(ODDS_ENDPOINTS)
      .merge(NEWS_ENDPOINTS)
      .freeze

    def self.find(key)
      ALL_ENDPOINTS[key.to_sym]
    end

    def self.all
      ALL_ENDPOINTS
    end
  end
end
