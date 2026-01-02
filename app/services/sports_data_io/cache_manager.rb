# frozen_string_literal: true

module SportsDataIO
  class CacheManager
    def initialize
      @cache = Rails.cache
    end

    def get(key)
      @cache.read(key)
    end

    def set(key, data, ttl)
      @cache.write(key, data, expires_in: ttl.to_i)
    end

    def delete(key)
      @cache.delete(key)
    end

    def clear_pattern(pattern)
      # Rails.cache doesn't support pattern deletion by default
      # For production, use Redis with redis-rails gem
      # For now, this is a no-op for memory store
      Rails.logger.info "Cache clear pattern requested: #{pattern}"
    end
  end
end
