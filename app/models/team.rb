class Team < ApplicationRecord
  SUPPORTED_SPORTS = %w[NFL NBA MLB NHL EPL MLS].freeze

  validates :name, presence: true, uniqueness: { scope: :sport }
  validates :sport, presence: true, inclusion: { in: SUPPORTED_SPORTS }
  validates :api_id, presence: true, uniqueness: true

  scope :for_sport, ->(sport) { where(sport: sport) }
  scope :by_name, -> { order(:name) }

  def primary_color
    colors&.dig("primary")
  end

  def secondary_color
    colors&.dig("secondary")
  end

  def display_name
    "#{name} (#{sport})"
  end
end
