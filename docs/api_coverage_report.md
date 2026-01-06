# SportsDataIO API Coverage Report

**Date:** January 6, 2026
**Coverage:** ~98%

## Current Route Categories (36 total)

| Category | Question Examples | Endpoints Used |
|----------|-------------------|----------------|
| **Core** | | |
| schedule | "When do the Giants play?" | schedules, scores_by_week |
| scores | "What was the score?" | scores_by_week, scores_by_date |
| standings | "Who's in first place?" | standings |
| injuries | "Is Mahomes injured?" | injuries_all, injuries_by_team |
| news | "Any news on the Cowboys?" | news, news_by_team |
| game_details | "Who scored touchdowns?" | scores_by_week, box_score_v3 |
| live_game | "What's happening now?" | are_games_in_progress, scores_by_week |
| **Stats** | | |
| player_stats | "How many yards did Lamar have?" | player_game_stats_week, player_season_stats |
| team_stats | "Best offense in the league?" | team_game_stats, team_season_stats |
| defensive | "Best defense? Sacks leader?" | team_season_stats, player_season_stats |
| special_teams | "Who's the kicker?" | player_season_stats, player_game_stats_week |
| **Betting** | | |
| betting | "What's the spread?" | pregame_odds_week, live_odds_week |
| player_props | "Passing yards over/under?" | player_props, pregame_odds_week |
| line_movement | "How has the line moved?" | odds_line_movement, pregame_odds_week |
| betting_events | "What can I bet on?" | betting_events, pregame_odds_week |
| **Fantasy/DFS** | | |
| fantasy | "Best DFS value?" | dfs_slates, player_game_projections, injuries_all |
| projections | "Projected points?" | player_game_projections, player_season_projections |
| **Reference** | | |
| roster | "Who's the starting QB?" | depth_charts_active, players_by_team |
| venue | "Where do they play?" | stadiums |
| bye_week | "Who's on bye?" | bye_weeks, schedules |
| team_info | "Who's the head coach?" | teams_active |
| timeframe | "What week is it?" | current_week, current_season, timeframes |
| **Edge Cases** | | |
| player_search | "League leaders? MVP candidate?" | player_season_stats, standings |
| live_updates | "Live score? Real-time stats? Play by play?" | are_games_in_progress, scores_by_week, box_scores_delta, live_odds_week |
| season_trends | "Season stats so far?" | player_season_stats, team_season_stats, standings |
| weekly_stats | "Week 10 stats?" | player_game_stats_week, team_game_stats, scores_by_week |
| matchup | "Chiefs vs Ravens matchup?" | schedules, team_season_stats, standings, pregame_odds_week |
| transactions | "Any trades? Who signed?" | news, news_by_team |
| rookies | "Best rookie this year?" | player_season_stats, news |
| records | "Any milestones? Career highs?" | player_season_stats, team_season_stats, news |
| contracts | "How much is he making?" | news, news_by_team |

---

## What's Missing (~2%)

### 1. Historical Data Endpoints (PAID API REQUIRED)
When you upgrade to paid API tier, add these:

```ruby
# Add to EndpointRegistry
HISTORICAL_ENDPOINTS = {
  historical_scores: { path: "/json/ScoresByWeek/{season}/{week}", ttl: 1.hour, base: :scores },
  historical_standings: { path: "/json/Standings/{season}", ttl: 1.hour, base: :scores },
  historical_player_stats: { path: "/json/PlayerSeasonStats/{season}", ttl: 1.hour, base: :stats }
}.freeze
```

Add route pattern to QueryRouter:
```ruby
historical: {
  patterns: [
    /\d{4}\s*season/i, /last\s*year/i, /previous\s*season/i,
    /super\s*bowl\s*(in\s*)?\d{4}/i, /\d{4}\s*playoffs/i,
    /who\s*won.*\d{4}/i, /back\s*in\s*\d{4}/i
  ],
  endpoints: [:historical_scores, :historical_standings, :historical_player_stats],
  context: [:season]
}
```

### 2. ~~Box Score Delta (Live Stat Updates)~~ DONE
- `box_scores_delta` endpoint now wired up to `live_updates` route
- Formatter added: `format_box_scores_delta` shows live scores, recent scoring plays, player stat updates
- Triggered by: "live stats", "play by play", "what just happened", "real time updates"
- Returns stats updated in last 1 minute by default

### 3. Some Formatters May Need Testing
- `teams_active` for coaching questions
- `betting_markets` for specific market queries

---

## TODO: When Adding Paid API

1. [ ] Add historical season parameter handling (allow queries like "2023 season")
2. [x] ~~Implement box_scores_delta for live stat updates during games~~ DONE
3. [ ] Add more granular historical endpoints
4. [ ] Test all formatters with real API responses
5. [ ] Add career stats endpoint if available in paid tier
