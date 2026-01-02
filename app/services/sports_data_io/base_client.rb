# frozen_string_literal: true

require "net/http"
require "json"

module SportsDataIO
  class BaseClient
    class RateLimitError < StandardError; end
    class ApiError < StandardError; end

    def initialize
      @api_key = ENV["SPORTSDATA_API_KEY"]
      @cache = CacheManager.new
    end

    def get(endpoint_key, params = {})
      endpoint = EndpointRegistry.find(endpoint_key)
      raise "Unknown endpoint: #{endpoint_key}" unless endpoint

      path = build_path(endpoint[:base], endpoint[:path], params)
      cache_key = build_cache_key(endpoint_key, params)

      # Check cache first
      cached = @cache.get(cache_key)
      return cached if cached

      # Make API call
      response = make_request(path)
      handle_response(response, endpoint_key, cache_key, endpoint[:ttl])
    end

    private

    def build_path(base, path_template, params)
      base_path = SportsDataIO::ENDPOINTS[base]
      full_path = "#{base_path}#{path_template}"

      # Substitute path parameters
      params.each do |key, value|
        full_path = full_path.gsub("{#{key}}", value.to_s)
      end

      full_path
    end

    def build_cache_key(endpoint_key, params)
      "sportsdata:#{endpoint_key}:#{params.sort.to_h.to_json}"
    end

    def make_request(path)
      uri = URI(path)
      request = Net::HTTP::Get.new(uri)
      request["Ocp-Apim-Subscription-Key"] = @api_key

      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      http.open_timeout = 10
      http.read_timeout = 30

      http.request(request)
    end

    def handle_response(response, endpoint_key, cache_key, ttl)
      case response.code.to_i
      when 200
        data = JSON.parse(response.body)
        @cache.set(cache_key, data, ttl) if ttl > 0
        data
      when 429
        raise RateLimitError, "Rate limit exceeded for #{endpoint_key}"
      when 401, 403
        raise ApiError, "Authentication failed - check your API key"
      else
        raise ApiError, "API error #{response.code}: #{response.body}"
      end
    rescue JSON::ParserError => e
      raise ApiError, "Invalid JSON response: #{e.message}"
    end
  end
end
