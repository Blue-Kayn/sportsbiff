module Api
  class BaseController < ApplicationController
    skip_before_action :verify_authenticity_token, only: [:create, :update]
    skip_before_action :check_onboarding
    before_action :authenticate_user!

    private

    def render_json(data, status: :ok)
      render json: data, status: status
    end

    def render_error(message, status: :unprocessable_entity)
      render json: { error: message }, status: status
    end
  end
end
