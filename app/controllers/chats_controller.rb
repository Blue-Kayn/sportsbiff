class ChatsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_chat, only: [ :show, :destroy ]
  before_action :ensure_team_channels_exist, only: [ :index ]

  def index
    @team_channels = current_user.chats.team_channels.includes(:team)
    @chats = current_user.chats.regular_chats.recent
    @chat = @chats.first || current_user.chats.build
  end

  def show
    @team_channels = current_user.chats.team_channels.includes(:team)
    @chats = current_user.chats.regular_chats.recent

    if @chat.team_channel?
      load_team_news
      render :team_channel
    else
      @messages = @chat.messages.chronological
      @message = Message.new
    end
  end

  def create
    @chat = current_user.chats.create!
    redirect_to @chat
  end

  def destroy
    # Don't allow deleting team channels
    if @chat.team_channel?
      redirect_to chats_path, alert: "Team channels cannot be deleted"
      return
    end

    @chat.destroy
    redirect_to chats_path, notice: "Chat deleted"
  end

  private

  def set_chat
    @chat = current_user.chats.find(params[:id])
  end

  def ensure_team_channels_exist
    favorite_team_ids = current_user.favorite_teams.map { |t| t["team_id"] }

    # Create channels for new favorite teams
    favorite_team_ids.each do |team_id|
      next if current_user.chats.team_channels.exists?(team_id: team_id)

      current_user.chats.create!(
        team_id: team_id,
        is_team_channel: true
      )
    end

    # Remove channels for teams no longer favorited
    current_user.chats.team_channels.where.not(team_id: favorite_team_ids).destroy_all
  end

  def load_team_news
    @team = @chat.team
    return unless @team

    # Use new dashboard service for NFL teams
    if @team.sport == "NFL"
      dashboard_service = TeamDashboardWebService.new(@team)
      @dashboard = dashboard_service.build_dashboard
    else
      # Fall back to old ESPN-based news for non-NFL teams
      news_service = NewsService.new
      sports_service = SportsDataService.new

      # Fetch team-specific news only (filtered by team name mentions)
      @news_items = news_service.team_news(@team)

      # Get recent game results (last 10 games) and format them for display
      raw_results = sports_service.recent_results([ @team.api_id ], days: 120, limit: 10)
      @recent_games = raw_results.map do |game|
        home = game[:home_team]
        away = game[:away_team]
        {
          result: "#{away[:name]} #{away[:score]} @ #{home[:name]} #{home[:score]}",
          date: game[:date],
          winner: home[:winner] ? home[:name] : away[:name]
        }
      end

      # Get today's upcoming games
      @upcoming_games = sports_service.games_for_teams([ @team.api_id ], Date.today)
    end
  end
end
