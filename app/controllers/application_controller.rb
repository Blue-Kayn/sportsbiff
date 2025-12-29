class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  before_action :check_onboarding

  private

  def check_onboarding
    return unless user_signed_in?
    return if devise_controller?
    return if is_a?(OnboardingController)
    return if current_user.onboarded?

    redirect_to onboarding_path
  end
end
