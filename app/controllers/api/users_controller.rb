module Api
  class UsersController < BaseController
    # POST /api/user/favorite_team
    def set_favorite_team
      team_name = params[:team]

      if team_name.present?
        # Update user's favorite team
        # The user model should have a method to handle this
        if current_user.respond_to?(:set_favorite_team)
          current_user.set_favorite_team(team_name)
        else
          # Fallback: append to favorite_teams if it's an array attribute
          current_user.update(favorite_teams: [team_name])
        end

        render_json({ success: true, team: team_name })
      else
        render_error("Team name is required")
      end
    end

    # GET /api/user/favorite_team
    def favorite_team
      team = current_user.favorite_team_names&.first
      render_json({ team: team })
    end
  end
end
