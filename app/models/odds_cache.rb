class OddsCache < ApplicationRecord
  CACHE_DURATION = 1.hour

  validates :sport, presence: true
  validates :event_id, presence: true, uniqueness: { scope: :sport }

  scope :for_sport, ->(sport) { where(sport: sport) }
  scope :fresh, -> { where("fetched_at > ?", CACHE_DURATION.ago) }
  scope :stale, -> { where("fetched_at <= ?", CACHE_DURATION.ago) }

  def fresh?
    fetched_at.present? && fetched_at > CACHE_DURATION.ago
  end

  def stale?
    !fresh?
  end

  def self.get_or_fetch(sport:, event_id:)
    cache = find_by(sport: sport, event_id: event_id)
    return cache.data if cache&.fresh?

    nil
  end

  def self.store(sport:, event_id:, data:)
    cache = find_or_initialize_by(sport: sport, event_id: event_id)
    cache.update!(data: data, fetched_at: Time.current)
    cache
  end
end
