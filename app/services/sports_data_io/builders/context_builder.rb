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
        when :player_game_stats_week
          format_player_game_stats(data, entities)
        when :player_season_stats
          format_player_season_stats(data, entities)
        when :team_game_stats
          format_team_game_stats(data, entities)
        when :team_season_stats
          format_team_season_stats(data, entities)
        when :pregame_odds_week, :live_odds_week
          format_odds(data, entities)
        when :depth_charts_active
          format_depth_charts(data, entities)
        when :players_by_team
          format_players_roster(data, entities)
        when :bye_weeks
          format_bye_weeks(data, entities)
        when :stadiums
          format_stadiums(data, entities)
        when :player_props
          format_player_props(data, entities)
        when :odds_line_movement
          format_line_movement(data, entities)
        when :dfs_slates
          format_dfs_slates(data, entities)
        when :player_game_projections, :player_season_projections
          format_projections(data, entities)
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
            record = "#{s['Wins']}-#{s['Losses']}"
            record += "-#{s['Ties']}" if s['Ties'].to_i > 0
            div_rank = s['DivisionRank']
            conf_rank = s['ConferenceRank']
            division = "#{s['Conference']} #{s['Division']}"

            # Include division rank and playoff implications
            rank_info = "##{div_rank} in #{division}"
            rank_info += " (DIVISION LEADER - PLAYOFF BERTH)" if div_rank == 1
            rank_info += ", ##{conf_rank} in #{s['Conference']}"

            lines << "- #{s['Name'] || s['Team']}: #{record} - #{rank_info}"
          end
        else
          # Show all teams grouped by division
          grouped = data.group_by { |s| "#{s['Conference']} #{s['Division']}" }
          grouped.each do |div, teams|
            lines << "\n### #{div}"
            teams.sort_by { |t| t['DivisionRank'] || 99 }.first(4).each do |s|
              record = "#{s['Wins']}-#{s['Losses']}"
              record += "-#{s['Ties']}" if s['Ties'].to_i > 0
              div_leader = s['DivisionRank'] == 1 ? " (Division Leader)" : ""
              lines << "- #{s['Team']}: #{record}#{div_leader}"
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

      def format_player_game_stats(data, entities)
        return "" unless data.is_a?(Array) && data.any?

        team_keys = entities[:teams].map { |t| t["Key"] }

        # Filter to relevant teams if specified
        relevant = if team_keys.any?
          data.select { |p| team_keys.include?(p["Team"]) }
        else
          data.first(50) # Limit if no team filter
        end

        return "" if relevant.empty?

        lines = ["## Player Game Stats"]

        # Group by position for readability
        qbs = relevant.select { |p| p["Position"] == "QB" && (p["PassingYards"].to_i > 0 || p["PassingAttempts"].to_i > 0) }
        rbs = relevant.select { |p| ["RB", "FB"].include?(p["Position"]) && p["RushingYards"].to_i > 0 }
        wrs = relevant.select { |p| ["WR", "TE"].include?(p["Position"]) && p["ReceivingYards"].to_i > 0 }

        if qbs.any?
          lines << "\n### Quarterbacks"
          qbs.sort_by { |p| -(p["PassingYards"] || 0) }.first(5).each do |p|
            lines << "- #{p['Name']} (#{p['Team']}): #{p['PassingCompletions']}/#{p['PassingAttempts']}, #{p['PassingYards']} yds, #{p['PassingTouchdowns']} TD, #{p['PassingInterceptions']} INT, #{p['PassingRating']&.round(1)} rating"
          end
        end

        if rbs.any?
          lines << "\n### Rushing"
          rbs.sort_by { |p| -(p["RushingYards"] || 0) }.first(5).each do |p|
            lines << "- #{p['Name']} (#{p['Team']}): #{p['RushingAttempts']} carries, #{p['RushingYards']} yds, #{p['RushingTouchdowns']} TD"
          end
        end

        if wrs.any?
          lines << "\n### Receiving"
          wrs.sort_by { |p| -(p["ReceivingYards"] || 0) }.first(5).each do |p|
            lines << "- #{p['Name']} (#{p['Team']}): #{p['Receptions']} rec, #{p['ReceivingYards']} yds, #{p['ReceivingTouchdowns']} TD"
          end
        end

        lines.join("\n") + "\n"
      end

      def format_player_season_stats(data, entities)
        return "" unless data.is_a?(Array) && data.any?

        team_keys = entities[:teams].map { |t| t["Key"] }

        # Filter to relevant teams if specified
        relevant = if team_keys.any?
          data.select { |p| team_keys.include?(p["Team"]) }
        else
          data.first(100)
        end

        return "" if relevant.empty?

        lines = ["## Player Season Stats"]

        # Top passers
        qbs = relevant.select { |p| p["Position"] == "QB" && p["PassingYards"].to_i > 0 }
        if qbs.any?
          lines << "\n### Passing Leaders"
          qbs.sort_by { |p| -(p["PassingYards"] || 0) }.first(5).each do |p|
            lines << "- #{p['Name']} (#{p['Team']}): #{p['PassingYards']} yds, #{p['PassingTouchdowns']} TD, #{p['PassingInterceptions']} INT, #{p['PassingRating']&.round(1)} rating"
          end
        end

        # Top rushers
        rushers = relevant.select { |p| p["RushingYards"].to_i > 100 }
        if rushers.any?
          lines << "\n### Rushing Leaders"
          rushers.sort_by { |p| -(p["RushingYards"] || 0) }.first(5).each do |p|
            lines << "- #{p['Name']} (#{p['Team']}): #{p['RushingYards']} yds, #{p['RushingTouchdowns']} TD, #{(p['RushingYards'].to_f / [p['RushingAttempts'].to_i, 1].max).round(1)} avg"
          end
        end

        # Top receivers
        receivers = relevant.select { |p| p["ReceivingYards"].to_i > 100 }
        if receivers.any?
          lines << "\n### Receiving Leaders"
          receivers.sort_by { |p| -(p["ReceivingYards"] || 0) }.first(5).each do |p|
            lines << "- #{p['Name']} (#{p['Team']}): #{p['Receptions']} rec, #{p['ReceivingYards']} yds, #{p['ReceivingTouchdowns']} TD"
          end
        end

        lines.join("\n") + "\n"
      end

      def format_team_game_stats(data, entities)
        return "" unless data.is_a?(Array) && data.any?

        team_keys = entities[:teams].map { |t| t["Key"] }

        relevant = if team_keys.any?
          data.select { |t| team_keys.include?(t["Team"]) }
        else
          data
        end

        return "" if relevant.empty?

        lines = ["## Team Game Stats"]

        relevant.each do |t|
          lines << "\n### #{t['Team']}"
          lines << "- Score: #{t['Score']}"
          lines << "- Total Yards: #{t['OffensiveYards']}"
          lines << "- Passing: #{t['PassingYards']} yds (#{t['PassingAttempts']} att, #{t['CompletionPercentage']&.round(1)}%)"
          lines << "- Rushing: #{t['RushingYards']} yds (#{t['RushingAttempts']} att)"
          lines << "- Turnovers: #{t['Giveaways']} (#{t['FumblesLost']} fumbles, #{t['InterceptionsThrownReturned'] || t['Interceptions']} INT)"
          lines << "- Time of Possession: #{t['TimeOfPossession']}" if t['TimeOfPossession']
          lines << "- Third Down: #{t['ThirdDownConversions']}/#{t['ThirdDownAttempts']}" if t['ThirdDownAttempts']
          lines << "- Red Zone: #{t['GoalToGoConversions']}/#{t['GoalToGoAttempts']}" if t['GoalToGoAttempts']
        end

        lines.join("\n") + "\n"
      end

      def format_team_season_stats(data, entities)
        return "" unless data.is_a?(Array) && data.any?

        team_keys = entities[:teams].map { |t| t["Key"] }

        relevant = if team_keys.any?
          data.select { |t| team_keys.include?(t["Team"]) }
        else
          data
        end

        return "" if relevant.empty?

        lines = ["## Team Season Stats"]

        relevant.each do |t|
          games = t['Games'].to_i
          games = 1 if games == 0

          lines << "\n### #{t['Team']}"
          lines << "- Points: #{t['Score']} total (#{(t['Score'].to_f / games).round(1)} per game)"
          lines << "- Points Allowed: #{t['OpponentScore']} total (#{(t['OpponentScore'].to_f / games).round(1)} per game)"
          lines << "- Total Yards/Game: #{(t['OffensiveYards'].to_f / games).round(1)}"
          lines << "- Passing Yards/Game: #{(t['PassingYards'].to_f / games).round(1)}"
          lines << "- Rushing Yards/Game: #{(t['RushingYards'].to_f / games).round(1)}"
          lines << "- Turnover Differential: #{t['TurnoverDifferential']}" if t['TurnoverDifferential']
          lines << "- Takeaways: #{t['Takeaways']}, Giveaways: #{t['Giveaways']}"
        end

        # If no specific team, show league leaders
        if team_keys.empty? && data.length > 10
          lines << "\n### League Rankings"

          # Best offenses
          lines << "\n**Top Scoring Offenses:**"
          data.sort_by { |t| -(t['Score'] || 0) }.first(5).each_with_index do |t, i|
            games = [t['Games'].to_i, 1].max
            lines << "#{i + 1}. #{t['Team']}: #{(t['Score'].to_f / games).round(1)} PPG"
          end

          # Best defenses
          lines << "\n**Top Scoring Defenses:**"
          data.sort_by { |t| t['OpponentScore'] || 999 }.first(5).each_with_index do |t, i|
            games = [t['Games'].to_i, 1].max
            lines << "#{i + 1}. #{t['Team']}: #{(t['OpponentScore'].to_f / games).round(1)} PPG allowed"
          end
        end

        lines.join("\n") + "\n"
      end

      def format_odds(data, entities)
        return "" unless data.is_a?(Array) && data.any?

        team_keys = entities[:teams].map { |t| t["Key"] }

        relevant = if team_keys.any?
          data.select { |g| team_keys.include?(g["HomeTeam"]) || team_keys.include?(g["AwayTeam"]) }
        else
          data
        end

        return "" if relevant.empty?

        lines = ["## Betting Odds"]

        relevant.first(10).each do |game|
          home = game["HomeTeam"]
          away = game["AwayTeam"]
          date = game["Date"] || game["DateTime"]

          lines << "\n### #{away} @ #{home}"
          lines << "Date: #{date}" if date

          # Get consensus odds (usually the first/main sportsbook)
          odds = game["PregameOdds"] || []
          consensus = odds.find { |o| o["Sportsbook"] == "Consensus" } || odds.first

          if consensus
            spread = consensus["HomePointSpread"]
            over_under = consensus["OverUnder"]
            home_ml = consensus["HomeMoneyLine"]
            away_ml = consensus["AwayMoneyLine"]

            if spread
              favorite = spread < 0 ? home : away
              spread_display = spread.abs
              lines << "- Spread: #{favorite} -#{spread_display}"
            end

            lines << "- Over/Under: #{over_under}" if over_under
            lines << "- Moneyline: #{home} #{home_ml}, #{away} #{away_ml}" if home_ml && away_ml
          end
        end

        lines.join("\n") + "\n"
      end

      def format_depth_charts(data, entities)
        return "" unless data.is_a?(Array) && data.any?

        team_keys = entities[:teams].map { |t| t["Key"] }

        relevant = if team_keys.any?
          data.select { |d| team_keys.include?(d["Team"]) }
        else
          data
        end

        return "" if relevant.empty?

        lines = ["## Depth Charts"]

        # Group by team
        grouped = relevant.group_by { |d| d["Team"] }

        grouped.each do |team, depth_entries|
          lines << "\n### #{team}"

          # Key positions only
          key_positions = ["QB", "RB", "WR1", "WR2", "TE", "LT", "LG", "C", "RG", "RT"]

          key_positions.each do |pos|
            starters = depth_entries.select { |d| d["PositionCategory"] == pos || d["Position"] == pos }
              .sort_by { |d| d["DepthOrder"] || 99 }

            if starters.any?
              starter = starters.first
              backup = starters[1]
              depth_str = "#{starter['Name']} (#{starter['DepthOrder'] == 1 ? 'Starter' : "##{starter['DepthOrder']}"})"
              depth_str += ", #{backup['Name']} (Backup)" if backup
              lines << "- #{pos}: #{depth_str}"
            end
          end
        end

        lines.join("\n") + "\n"
      end

      def format_players_roster(data, entities)
        return "" unless data.is_a?(Array) && data.any?

        lines = ["## Team Roster"]

        # Group by position
        positions = data.group_by { |p| p["Position"] }

        # Show key position groups
        %w[QB RB WR TE].each do |pos|
          players = positions[pos]
          next unless players&.any?

          lines << "\n### #{pos}s"
          players.each do |p|
            status = p["Status"] || "Active"
            injury_status = p["InjuryStatus"]
            status_display = injury_status ? "#{status} - #{injury_status}" : status
            lines << "- #{p['Name']} ##{p['Number']} (#{status_display})"
          end
        end

        lines.join("\n") + "\n"
      end

      def format_bye_weeks(data, entities)
        return "" unless data.is_a?(Array) && data.any?

        team_keys = entities[:teams].map { |t| t["Key"] }

        lines = ["## Bye Weeks"]

        if team_keys.any?
          relevant = data.select { |b| team_keys.include?(b["Team"]) }
          relevant.each do |bye|
            lines << "- #{bye['Team']}: Week #{bye['Week']} bye"
          end
        else
          # Group by week
          grouped = data.group_by { |b| b["Week"] }
          grouped.sort_by { |w, _| w }.each do |week, teams|
            team_list = teams.map { |t| t["Team"] }.join(", ")
            lines << "- Week #{week}: #{team_list}"
          end
        end

        lines.join("\n") + "\n"
      end

      def format_stadiums(data, entities)
        return "" unless data.is_a?(Array) && data.any?

        team_keys = entities[:teams].map { |t| t["Key"] }

        lines = ["## Stadiums"]

        relevant = if team_keys.any?
          # Find stadiums for the specified teams
          data.select { |s| team_keys.any? { |tk| s["Name"]&.include?(tk) || s["City"]&.include?(tk) } }
        else
          data.first(10)
        end

        relevant.each do |stadium|
          capacity = stadium["Capacity"] ? " (#{stadium['Capacity'].to_i.to_s.reverse.gsub(/(\d{3})(?=\d)/, '\\1,').reverse} capacity)" : ""
          surface = stadium["PlayingSurface"] ? ", #{stadium['PlayingSurface']}" : ""
          type = stadium["Type"] || "Stadium"
          lines << "- #{stadium['Name']}: #{stadium['City']}, #{stadium['State']}#{capacity}#{surface} - #{type}"
        end

        lines.join("\n") + "\n"
      end

      def format_player_props(data, entities)
        return "" unless data.is_a?(Array) && data.any?

        lines = ["## Player Props"]

        # Group by player
        grouped = data.group_by { |p| p["PlayerName"] || p["Name"] }

        grouped.first(10).each do |player_name, props|
          next unless player_name

          lines << "\n### #{player_name}"
          props.first(5).each do |prop|
            bet_type = prop["BetType"] || prop["MarketType"] || "Prop"
            line = prop["Line"] || prop["OverUnder"]
            over_payout = prop["OverPayout"] || prop["OverOdds"]
            under_payout = prop["UnderPayout"] || prop["UnderOdds"]

            if line
              lines << "- #{bet_type}: #{line} (Over: #{over_payout}, Under: #{under_payout})"
            end
          end
        end

        lines.join("\n") + "\n"
      end

      def format_line_movement(data, entities)
        return "" unless data.is_a?(Array) || data.is_a?(Hash)

        lines = ["## Line Movement"]

        # Handle both array and hash responses
        movements = data.is_a?(Array) ? data : [data]

        movements.first(20).each do |move|
          timestamp = move["DateTime"] || move["Created"]
          spread = move["HomePointSpread"] || move["PointSpread"]
          over_under = move["OverUnder"]
          sportsbook = move["Sportsbook"] || "Consensus"

          if timestamp && (spread || over_under)
            time_str = begin
              Time.parse(timestamp).strftime("%m/%d %I:%M%p")
            rescue
              timestamp
            end
            lines << "- #{time_str} (#{sportsbook}): Spread #{spread}, O/U #{over_under}"
          end
        end

        if lines.length == 1
          lines << "- No line movement data available"
        end

        lines.join("\n") + "\n"
      end

      def format_dfs_slates(data, entities)
        return "" unless data.is_a?(Array) && data.any?

        lines = ["## DFS Slates"]

        data.first(5).each do |slate|
          operator = slate["Operator"] || "Unknown"
          name = slate["Name"] || slate["SlateName"] || "Main"
          game_count = slate["NumberOfGames"] || slate["Games"]&.length || 0

          lines << "\n### #{operator} - #{name}"
          lines << "- Games: #{game_count}"

          # Show salary info if available
          players = slate["DfsSlateGames"] || slate["Players"] || []
          if players.any?
            lines << "- Top Salaries:"
            players.flatten.first(5).each do |player|
              if player["OperatorPlayerName"] && player["OperatorSalary"]
                lines << "  - #{player['OperatorPlayerName']}: $#{player['OperatorSalary']}"
              end
            end
          end
        end

        lines.join("\n") + "\n"
      end

      def format_projections(data, entities)
        return "" unless data.is_a?(Array) && data.any?

        team_keys = entities[:teams].map { |t| t["Key"] }

        relevant = if team_keys.any?
          data.select { |p| team_keys.include?(p["Team"]) }
        else
          data.first(50)
        end

        return "" if relevant.empty?

        lines = ["## Player Projections"]

        # QBs
        qbs = relevant.select { |p| p["Position"] == "QB" && p["PassingYards"].to_f > 0 }
        if qbs.any?
          lines << "\n### Quarterbacks"
          qbs.sort_by { |p| -(p["FantasyPoints"] || p["PassingYards"] || 0) }.first(5).each do |p|
            fantasy = p["FantasyPoints"] ? " (#{p['FantasyPoints'].round(1)} pts)" : ""
            lines << "- #{p['Name']} (#{p['Team']}): #{p['PassingYards']&.round} pass yds, #{p['PassingTouchdowns']&.round} TD proj#{fantasy}"
          end
        end

        # RBs
        rbs = relevant.select { |p| p["Position"] == "RB" && p["RushingYards"].to_f > 0 }
        if rbs.any?
          lines << "\n### Running Backs"
          rbs.sort_by { |p| -(p["FantasyPoints"] || p["RushingYards"] || 0) }.first(5).each do |p|
            fantasy = p["FantasyPoints"] ? " (#{p['FantasyPoints'].round(1)} pts)" : ""
            lines << "- #{p['Name']} (#{p['Team']}): #{p['RushingYards']&.round} rush yds, #{p['RushingTouchdowns']&.round} TD proj#{fantasy}"
          end
        end

        # WRs/TEs
        receivers = relevant.select { |p| ["WR", "TE"].include?(p["Position"]) && p["ReceivingYards"].to_f > 0 }
        if receivers.any?
          lines << "\n### Receivers"
          receivers.sort_by { |p| -(p["FantasyPoints"] || p["ReceivingYards"] || 0) }.first(5).each do |p|
            fantasy = p["FantasyPoints"] ? " (#{p['FantasyPoints'].round(1)} pts)" : ""
            lines << "- #{p['Name']} (#{p['Team']}): #{p['Receptions']&.round} rec, #{p['ReceivingYards']&.round} yds proj#{fantasy}"
          end
        end

        lines.join("\n") + "\n"
      end
    end
  end
end
