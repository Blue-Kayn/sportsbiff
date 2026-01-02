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
