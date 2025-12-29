class OddsSyncJob < ApplicationJob
  queue_as :default

  def perform(sport = "americanfootball_nfl")
    Rails.logger.info("OddsSyncJob: Syncing odds for #{sport}")

    service = OddsApiService.new(sport: sport)
    events = service.fetch_upcoming_events

    if events.nil?
      Rails.logger.error("OddsSyncJob: Failed to fetch events for #{sport}")
      return
    end

    events.each do |event|
      OddsCache.store(
        sport: sport,
        event_id: event["id"],
        data: event
      )
    end

    Rails.logger.info("OddsSyncJob: Cached #{events.count} events for #{sport}")
  end
end
