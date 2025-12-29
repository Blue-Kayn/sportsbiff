class ProfileController < ApplicationController
  before_action :authenticate_user!

  def show
    @sports = Team::SUPPORTED_SPORTS
    @teams_by_sport = {}

    @sports.each do |sport|
      @teams_by_sport[sport] = Team.for_sport(sport).by_name
    end

    @selected_sports = current_user.favorite_sports || []
    @selected_team_ids = current_user.favorite_team_ids || []
  end

  def update_sports
    sports = params[:sports]&.reject(&:blank?) || []

    if sports.empty?
      flash[:alert] = "Please select at least one sport"
      redirect_to profile_path
      return
    end

    # Remove teams from sports that are no longer selected
    remaining_teams = current_user.favorite_teams.select do |team|
      sports.include?(team["sport"])
    end

    current_user.update!(
      favorite_sports: sports,
      favorite_teams: remaining_teams
    )

    flash[:notice] = "Sports updated successfully"
    redirect_to profile_path
  end

  def update_teams
    team_ids = params[:team_ids]&.reject(&:blank?) || []

    # Build favorite_teams array from selected team IDs
    favorite_teams = team_ids.map do |team_id|
      team = Team.find_by(api_id: team_id)
      next unless team
      next unless current_user.favorite_sports.include?(team.sport)

      {
        "sport" => team.sport,
        "team_id" => team.api_id,
        "team_name" => team.name
      }
    end.compact

    current_user.update!(favorite_teams: favorite_teams)

    flash[:notice] = "Teams updated successfully"
    redirect_to profile_path
  end
end
