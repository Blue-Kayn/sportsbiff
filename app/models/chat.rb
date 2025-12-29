class Chat < ApplicationRecord
  belongs_to :user
  belongs_to :team, primary_key: :api_id, foreign_key: :team_id, optional: true
  has_many :messages, dependent: :destroy

  SUPPORTED_SPORTS = %w[americanfootball_nfl].freeze

  validates :sport, inclusion: { in: SUPPORTED_SPORTS }, allow_nil: true
  validates :team_id, uniqueness: { scope: :user_id }, allow_nil: true

  before_create :set_default_sport
  before_create :set_default_title

  scope :recent, -> { order(updated_at: :desc) }
  scope :team_channels, -> { where(is_team_channel: true) }
  scope :regular_chats, -> { where(is_team_channel: false) }

  def display_title
    return team.name if is_team_channel && team.present?
    title.presence || "New Chat"
  end

  def team_channel?
    is_team_channel
  end

  private

  def set_default_sport
    self.sport ||= "americanfootball_nfl"
  end

  def set_default_title
    self.title ||= "New Chat" unless is_team_channel
  end
end
