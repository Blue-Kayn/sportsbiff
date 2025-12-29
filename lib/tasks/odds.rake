namespace :odds do
  desc "Refresh odds cache for all supported sports"
  task refresh: :environment do
    sports = [ "americanfootball_nfl" ]

    sports.each do |sport|
      puts "Refreshing odds for #{sport}..."
      OddsSyncJob.perform_now(sport)
    end

    puts "Done! Cached #{OddsCache.fresh.count} fresh events."
  end

  desc "Clear all cached odds"
  task clear: :environment do
    count = OddsCache.count
    OddsCache.delete_all
    puts "Cleared #{count} cached odds entries."
  end

  desc "Show current cache status"
  task status: :environment do
    puts "Odds Cache Status:"
    puts "-" * 40

    fresh_count = OddsCache.fresh.count
    stale_count = OddsCache.stale.count
    total_count = OddsCache.count

    puts "Fresh entries: #{fresh_count}"
    puts "Stale entries: #{stale_count}"
    puts "Total entries: #{total_count}"

    if OddsCache.any?
      oldest = OddsCache.order(:fetched_at).first
      newest = OddsCache.order(fetched_at: :desc).first
      puts "\nOldest entry: #{oldest.fetched_at}"
      puts "Newest entry: #{newest.fetched_at}"
    end
  end
end
