# frozen_string_literal: true

module SportsDataIO
  module Builders
    class ContextBuilder
      def initialize
        @client = BaseClient.new
        @context_service = ContextService.new
        @router = QueryRouter.new
      end

      def build_for_question(question, user_team_ids = [])
        # 1. Bootstrap temporal context
        base_context = @context_service.bootstrap
        season = base_context[:season]
        week = base_context[:week]
        teams_lookup = base_context[:teams]

        # 2. Route question to determine what data we need
        routes = @router.route(question, base_context)
        entities = @router.extract_entities(question, teams_lookup)

        # Add user's favorite teams to entities if not already detected
        if entities[:teams].empty? && user_team_ids.any?
          user_team_ids.each do |team_id|
            team = teams_lookup[team_id]
            entities[:teams] << team if team
          end
        end

        # 3. Fetch only the data we need
        data = {}
        routes.each do |route|
          route[:endpoints].each do |endpoint|
            # Skip box_score_v3 here - we'll fetch it after getting scores
            next if endpoint == :box_score_v3

            params = build_params(endpoint, season, week, entities)
            begin
              result = @client.get(endpoint, params)

              # For scores, also fetch previous week to include recent completed games
              if endpoint == :scores_by_week && week.to_i > 1
                prev_week_params = params.merge(week: week.to_i - 1)
                prev_result = @client.get(endpoint, prev_week_params)
                if prev_result.is_a?(Array) && result.is_a?(Array)
                  result = prev_result + result
                end
              end

              data[endpoint] = result
            rescue => e
              Rails.logger.warn "Failed to fetch #{endpoint}: #{e.message}"
            end
          end
        end

        # If box_score_v3 is needed, find the relevant game and fetch it
        needs_box_score = routes.any? { |r| r[:endpoints].include?(:box_score_v3) }
        if needs_box_score && entities[:teams].any?
          fetch_box_score_for_team(data, season, week, entities)
        end

        # 4. Build the context string for AI
        build_context_string(question, base_context, entities, data)
      rescue => e
        Rails.logger.error "Context builder error: #{e.message}"
        Rails.logger.error e.backtrace.join("\n")
        "Unable to fetch current NFL data. Please try again."
      end

      private

      def fetch_box_score_for_team(data, season, week, entities)
        team_keys = entities[:teams].map { |t| t["Key"] }
        team_game = nil

        # Try current week first, then go back up to 3 weeks to find a completed game
        weeks_to_check = [week.to_i, week.to_i - 1, week.to_i - 2].select { |w| w > 0 }

        weeks_to_check.each do |check_week|
          begin
            scores = @client.get(:scores_by_week, { season: season, week: check_week })
            next unless scores.is_a?(Array)

            # Find completed game for this team
            team_game = scores
              .select { |g| (team_keys.include?(g["HomeTeam"]) || team_keys.include?(g["AwayTeam"])) && g["Status"] == "Final" }
              .max_by { |g| g["Date"] || "" }

            break if team_game
          rescue => e
            Rails.logger.warn "Failed to fetch scores for week #{check_week}: #{e.message}"
          end
        end

        return unless team_game

        score_id = team_game["ScoreID"]
        return unless score_id

        begin
          box_score = @client.get(:box_score_v3, { scoreid: score_id })
          data[:box_score_v3] = box_score if box_score
        rescue => e
          Rails.logger.warn "Failed to fetch box score: #{e.message}"
        end
      end

      def build_params(endpoint, season, week, entities)
        params = {}

        # Get the endpoint definition to check what params it needs
        endpoint_def = EndpointRegistry.find(endpoint)
        return params unless endpoint_def

        path = endpoint_def[:path]

        # Auto-detect required params from path template
        params[:season] = season if path.include?('{season}')
        params[:week] = week if path.include?('{week}')

        # Add team if detected and endpoint needs it
        if path.include?('{team}') && entities[:teams].any?
          params[:team] = entities[:teams].first["Key"]
        end

        # Add date if needed
        if path.include?('{date}') && entities[:dates].any?
          params[:date] = entities[:dates].first.strftime("%Y-%b-%d").upcase
        end

        # Add scoreid if needed (for box scores)
        if path.include?('{scoreid}') && entities[:scoreid]
          params[:scoreid] = entities[:scoreid]
        end

        # Add type if needed (for timeframes)
        if path.include?('{type}') && entities[:type]
          params[:type] = entities[:type]
        end

        # Add playerstoinclude if needed (for box score deltas)
        if path.include?('{playerstoinclude}')
          params[:playerstoinclude] = entities[:playerstoinclude] || 'all'
        end

        # Add minutes if needed (for box score deltas)
        if path.include?('{minutes}')
          params[:minutes] = entities[:minutes] || '1'
        end

        params
      end

      def build_context_string(question, base_context, entities, data)
        parts = []

        # Temporal context
        parts << "## Current NFL Context"
        parts << "- Season: #{base_context[:season]}"
        parts << "- Week: #{base_context[:week]}"
        parts << "- Games In Progress: #{base_context[:games_in_progress]}"
        parts << ""

        # Entity context
        if entities[:teams].any?
          parts << "## Teams Mentioned"
          entities[:teams].each do |team|
            parts << "- #{team['FullName']} (#{team['Key']})"
          end
          parts << ""
        end

        # Data context
        data.each do |endpoint, response|
          next unless response
          parts << format_data_section(endpoint, response, entities)
        end

        parts.join("\n")
      end

      def format_data_section(endpoint, data, entities)
        case endpoint
        when :schedules
          format_schedule(data, entities)
        when :standings
          format_standings(data, entities)
        when :scores_by_week, :scores_by_date
          format_scores(data, entities)
        when :injuries_all, :injuries_by_team
          format_injuries(data, entities)
        when :news, :news_by_team
          format_news(data, entities)
        when :box_score_v3
          format_box_score(data, entities)
        else
          ""
        end
      end

      def format_schedule(data, entities)
        return "" unless data.is_a?(Array) && data.any?

        today = Date.current

        relevant = if entities[:teams].any?
          team_keys = entities[:teams].map { |t| t["Key"] }
          data.select { |g| team_keys.include?(g["HomeTeam"]) || team_keys.include?(g["AwayTeam"]) }
        else
          data
        end

        # Filter for future games only (games that haven't happened yet)
        future_games = relevant.select do |game|
          next false if game["Status"] == "Final" || game["Status"] == "F/OT"
          next false if game["AwayTeam"] == "BYE" || game["HomeTeam"] == "BYE"

          date_str = game["Date"] || game["DateTime"]
          next true unless date_str # Include if no date (TBD)

          begin
            game_date = Date.parse(date_str)
            game_date >= today
          rescue
            true
          end
        end

        return "" if future_games.empty?

        lines = ["## Upcoming Games (Future games only)"]
        future_games.first(5).each do |game|
          date_str = game["Date"] || game["DateTime"] || "TBD"
          channel = game["Channel"] || "N/A"
          lines << "- #{game['AwayTeam']} @ #{game['HomeTeam']} - #{date_str} (#{channel})"
        end
        lines.join("\n") + "\n"
      end

      def format_standings(data, entities)
        return "" unless data.is_a?(Array) && data.any?

        lines = ["## Standings"]

        if entities[:teams].any?
          team_keys = entities[:teams].map { |t| t["Key"] }
          relevant = data.select { |s| team_keys.include?(s["Team"]) }
          relevant.each do |s|
            lines << "- #{s['Team']}: #{s['Wins']}-#{s['Losses']}-#{s['Ties'] || 0}"
          end
        else
          # Show all teams grouped by division
          grouped = data.group_by { |s| "#{s['Conference']} #{s['Division']}" }
          grouped.each do |div, teams|
            lines << "\n### #{div}"
            teams.sort_by { |t| -t['Wins'] }.first(4).each do |s|
              lines << "- #{s['Team']}: #{s['Wins']}-#{s['Losses']}-#{s['Ties'] || 0}"
            end
          end
        end

        lines.join("\n") + "\n"
      end

      def format_scores(data, entities)
        return "" unless data.is_a?(Array) && data.any?

        # Filter to user's teams if specified
        relevant = if entities[:teams].any?
          team_keys = entities[:teams].map { |t| t["Key"] }
          data.select { |g| team_keys.include?(g["HomeTeam"]) || team_keys.include?(g["AwayTeam"]) }
        else
          data
        end

        return "" if relevant.empty?

        # Separate completed and upcoming games
        completed = relevant.select { |g| g['Status'] == 'Final' || g['Status'].to_s.downcase.include?('final') }
        in_progress = relevant.select { |g| g['Status'].to_s.downcase.include?('progress') }

        lines = []

        # Show completed games first (most recent)
        if completed.any?
          lines << "## Recent Results"
          completed.sort_by { |g| g['Date'] || '' }.reverse.first(5).each do |game|
            lines << "- #{game['AwayTeam']} #{game['AwayScore']} @ #{game['HomeTeam']} #{game['HomeScore']} (Final - #{game['Date']&.split('T')&.first})"
          end
          lines << ""
        end

        # Show in-progress games
        if in_progress.any?
          lines << "## Games In Progress"
          in_progress.each do |game|
            quarter = game['Quarter'] || game['CurrentQuarter'] || ''
            time_remaining = game['TimeRemaining'] || ''
            lines << "- #{game['AwayTeam']} #{game['AwayScore']} @ #{game['HomeTeam']} #{game['HomeScore']} (Q#{quarter} #{time_remaining})"
          end
          lines << ""
        end

        lines.join("\n")
      end

      def format_injuries(data, entities)
        return "" unless data.is_a?(Array) && data.any?

        lines = ["## Injury Report"]
        grouped = data.group_by { |i| i['Team'] }

        grouped.each do |team, injuries|
          lines << "\n### #{team}"
          injuries.first(10).each do |inj|
            player_name = inj['Name'] || inj['PlayerName'] || 'Unknown'
            position = inj['Position'] || ''
            status = inj['Status'] || inj['InjuryStatus'] || 'Out'
            body_part = inj['BodyPart'] || inj['Injury'] || ''
            lines << "- #{player_name} (#{position}): #{status} - #{body_part}"
          end
        end

        lines.join("\n") + "\n"
      end

      def format_news(data, entities)
        return "" unless data.is_a?(Array) && data.any?

        # Filter news to only include items about the user's teams
        team_keys = entities[:teams].map { |t| t["Key"] }
        relevant_news = if team_keys.any?
          data.select { |item| team_keys.include?(item['Team']) }
        else
          data
        end

        return "" if relevant_news.empty?

        lines = ["## Latest News"]
        relevant_news.first(5).each do |item|
          title = item['Title'] || item['Headline'] || ''
          source = item['Source'] || ''
          lines << "- #{title} (#{source})"
        end
        lines.join("\n") + "\n"
      end

      def format_box_score(data, entities)
        return "" unless data.is_a?(Hash)

        lines = []

        # Game info from Score
        score = data["Score"]
        if score
          away = score["AwayTeam"]
          home = score["HomeTeam"]
          away_score = score["AwayScore"]
          home_score = score["HomeScore"]
          date = score["Date"] || score["DateTime"]
          lines << "## Game Details: #{away} #{away_score} @ #{home} #{home_score}"
          lines << "Date: #{date}" if date
          lines << ""
        end

        # Scoring plays - this is the key data for "who scored first TD" questions
        scoring_plays = data["ScoringPlays"]
        if scoring_plays.is_a?(Array) && scoring_plays.any?
          lines << "## Scoring Plays (in order)"
          scoring_plays.sort_by { |p| p["Sequence"] || 0 }.each do |play|
            quarter = play["Quarter"]
            time = play["TimeRemaining"]
            team = play["Team"]
            description = play["PlayDescription"]
            away_score = play["AwayScore"]
            home_score = play["HomeScore"]
            lines << "- Q#{quarter} #{time}: #{description} (Score: #{score&.dig('AwayTeam')} #{away_score}, #{score&.dig('HomeTeam')} #{home_score})"
          end
          lines << ""
        end

        lines.join("\n")
      end
    end
  end
end
