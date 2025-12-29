class OnboardingController < ApplicationController
  before_action :authenticate_user!
  before_action :redirect_if_onboarded, except: [:complete]
  layout "onboarding"

  def index
    # Step 1: Select sports
    @sports = Team::SUPPORTED_SPORTS
    @selected_sports = current_user.favorite_sports || []
  end

  def sports
    # Save selected sports and move to team selection
    sports = params[:sports]&.reject(&:blank?) || []

    if sports.empty?
      flash.now[:alert] = "Please select at least one sport"
      @sports = Team::SUPPORTED_SPORTS
      @selected_sports = []
      render :index
      return
    end

    current_user.update!(favorite_sports: sports)
    redirect_to onboarding_teams_path
  end

  def teams
    # Step 2: Select teams
    @sports = current_user.favorite_sports
    @teams_by_sport = {}

    @sports.each do |sport|
      @teams_by_sport[sport] = Team.for_sport(sport).by_name
    end

    @selected_team_ids = current_user.favorite_teams.map { |t| t["team_id"] }
  end

  def save_teams
    # Save selected teams
    team_ids = params[:team_ids]&.reject(&:blank?) || []

    if team_ids.empty?
      flash.now[:alert] = "Please select at least one team"
      @sports = current_user.favorite_sports
      @teams_by_sport = {}
      @sports.each do |sport|
        @teams_by_sport[sport] = Team.for_sport(sport).by_name
      end
      @selected_team_ids = []
      render :teams
      return
    end

    # Build favorite_teams array from selected team IDs
    favorite_teams = team_ids.map do |team_id|
      team = Team.find_by(api_id: team_id)
      next unless team

      {
        "sport" => team.sport,
        "team_id" => team.api_id,
        "team_name" => team.name
      }
    end.compact

    current_user.update!(favorite_teams: favorite_teams)
    redirect_to onboarding_complete_path
  end

  def complete
    # Step 3: Complete onboarding
    current_user.complete_onboarding!
  end

  def finish
    redirect_to authenticated_root_path, notice: "Welcome to SportsBiff! Your personalized sports experience is ready."
  end

  private

  def redirect_if_onboarded
    redirect_to authenticated_root_path if current_user.onboarded?
  end
end
