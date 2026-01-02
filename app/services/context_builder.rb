# Assembles real-time context data for AI prompts
# Uses SportsDataIO for NFL, no ESPN calls
class ContextBuilder
  def initialize(user:, question:)
    @user = user
    @question = question.is_a?(String) ? question : question.content
    @nfl_context_builder = SportsDataIO::Builders::ContextBuilder.new if has_nfl_teams?
  end

  def has_nfl_teams?
    @user.favorite_sports&.include?("NFL") ||
    @user.favorite_teams&.any? { |t| t["sport"] == "NFL" }
  end

  # Format context as text for system prompt injection
  def to_prompt_text
    sections = []
    sections << "TODAY'S DATE: #{Date.current.strftime('%A, %B %d, %Y')}"

    # Add NFL-specific context if user has NFL teams
    if @nfl_context_builder
      begin
        nfl_team_ids = @user.favorite_teams
          &.select { |t| t["sport"] == "NFL" }
          &.map { |t| t["team_id"].to_s.upcase }

        Rails.logger.info "Building NFL context for teams: #{nfl_team_ids.inspect}"

        if nfl_team_ids&.any?
          nfl_context = @nfl_context_builder.build_for_question(@question, nfl_team_ids)
          Rails.logger.info "NFL context result: #{nfl_context.present? ? 'SUCCESS' : 'EMPTY'}"
          sections << nfl_context if nfl_context.present?
        end
      rescue => e
        Rails.logger.error "NFL context error: #{e.message}"
        Rails.logger.error e.backtrace.join("\n")
      end
    end

    # Add user's favorite teams
    if @user.favorite_teams.present?
      team_list = @user.favorite_teams.map { |t| "#{t['team_name']} (#{t['sport']})" }.join(", ")
      sections << "USER'S FAVORITE TEAMS: #{team_list}"
    end

    sections.join("\n\n")
  end

end
