# frozen_string_literal: true

module SportsDataIO
  class QueryRouter
    PATTERNS = {
      # Schedule Questions
      schedule: {
        patterns: [/when.*(play|game|next)/i, /what time/i, /schedule/i, /who.*(play|face|against)/i],
        endpoints: [:schedules, :scores_by_week],
        context: [:teams, :season, :week]
      },

      # Score Questions
      scores: {
        patterns: [/score/i, /win|won|lost|lose/i, /result/i, /beat/i, /final/i, /last.*game/i, /previous.*game/i, /recent.*game/i, /how did.*do/i, /last\s+\w+\s+game/i],
        endpoints: [:scores_by_week, :scores_by_date],
        context: [:teams, :season, :week]
      },

      # Game Details (touchdowns, plays, box score)
      game_details: {
        patterns: [/touchdown/i, /td\b/i, /who scored/i, /first.*score/i, /scoring/i, /stats/i, /box score/i, /how.*score/i, /plays?/i],
        endpoints: [:scores_by_week, :box_score_v3],
        context: [:teams, :season, :week],
        needs_scoreid: true
      },

      # Live Game Questions
      live_game: {
        patterns: [/live/i, /current.*game/i, /right now/i, /happening/i, /playing now/i],
        endpoints: [:are_games_in_progress, :scores_by_week],
        context: [:teams, :season, :week]
      },

      # Standings Questions
      standings: {
        patterns: [/standing/i, /record/i, /playoff/i, /division/i, /conference/i, /rank/i],
        endpoints: [:standings],
        context: [:teams, :season]
      },

      # Injury Questions
      injuries: {
        patterns: [/injur/i, /hurt/i, /out\b/i, /questionable/i, /doubtful/i, /probable/i, /ir\b/i],
        endpoints: [:injuries_all, :injuries_by_team],
        context: [:teams, :season, :week]
      },

      # News Questions
      news: {
        patterns: [/news/i, /update/i, /latest/i, /report/i],
        endpoints: [:news, :news_by_team],
        context: [:teams]
      },

      # Player Stats Questions
      player_stats: {
        patterns: [
          /how did .* do/i, /how many (yards|touchdowns|passes|receptions|carries)/i,
          /passing yards/i, /rushing yards/i, /receiving yards/i,
          /quarterback|qb\b/i, /running back|rb\b/i, /wide receiver|wr\b/i,
          /fantasy points/i, /player stats/i, /stat line/i,
          /threw for/i, /ran for/i, /caught/i, /completions/i,
          /interceptions/i, /fumbles/i, /sacks/i
        ],
        endpoints: [:player_game_stats_week, :player_season_stats],
        context: [:teams, :season, :week]
      },

      # Team Stats Questions
      team_stats: {
        patterns: [
          /team stats/i, /offensive stats/i, /defensive stats/i,
          /total yards/i, /yards per game/i, /points per game/i,
          /best offense/i, /best defense/i, /worst offense/i, /worst defense/i,
          /turnover/i, /red zone/i, /third down/i,
          /how many points/i, /scoring offense/i, /scoring defense/i,
          /yards allowed/i, /points allowed/i
        ],
        endpoints: [:team_game_stats, :team_season_stats],
        context: [:teams, :season, :week]
      },

      # Betting/Odds Questions
      betting: {
        patterns: [
          /odds/i, /spread/i, /line/i, /over.?under/i, /o\/u/i,
          /moneyline/i, /money line/i, /point spread/i,
          /favorite/i, /underdog/i, /vegas/i, /betting/i,
          /what('s| is) the line/i, /who('s| is) favored/i
        ],
        endpoints: [:pregame_odds_week, :live_odds_week],
        context: [:teams, :season, :week]
      },

      # Depth Chart/Roster Questions
      roster: {
        patterns: [
          /depth chart/i, /starting/i, /starter/i, /backup/i,
          /roster/i, /who('s| is) starting/i, /first string/i,
          /second string/i, /lineup/i, /players on/i
        ],
        endpoints: [:depth_charts_active, :players_by_team],
        context: [:teams]
      }
    }.freeze

    def route(question, context = {})
      matched_categories = []

      PATTERNS.each do |category, config|
        if config[:patterns].any? { |p| question.match?(p) }
          matched_categories << {
            category: category,
            endpoints: config[:endpoints],
            required_context: config[:context]
          }
        end
      end

      # Default to general info if nothing matches
      if matched_categories.empty?
        matched_categories << {
          category: :general,
          endpoints: [:schedules, :standings],
          required_context: [:teams, :season, :week]
        }
      end

      matched_categories
    end

    def extract_entities(question, teams_lookup)
      entities = { teams: [], dates: [] }

      # Extract team mentions
      teams_lookup.each do |key, team|
        names = [team["Key"], team["Name"], team["City"], team["FullName"]].compact
        names.each do |name|
          if question.downcase.include?(name.downcase)
            entities[:teams] << team
            break
          end
        end
      end

      # Extract date references
      entities[:dates] << Date.today if question.match?(/today/i)
      entities[:dates] << Date.tomorrow if question.match?(/tomorrow/i)
      entities[:dates] << Date.yesterday if question.match?(/yesterday/i)

      # Extract week references
      entities[:week_reference] = :current if question.match?(/this week/i)
      entities[:week_reference] = :next if question.match?(/next week/i)
      entities[:week_reference] = :last if question.match?(/last week/i)

      entities
    end
  end
end
