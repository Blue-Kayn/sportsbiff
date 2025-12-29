class DashboardController < ApplicationController
  before_action :authenticate_user!

  def index
    @recent_chats = current_user.chats.recent.limit(5)
    @queries_remaining = current_user.queries_remaining
    @daily_limit = current_user.daily_limit
  end
end
