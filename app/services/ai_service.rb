class AiService
  # Standard model for API-based responses (betting data, live scores)
  MODEL = "gpt-4o-mini"

  # Web search model - OpenAI's search-enabled model with built-in web search
  # Costs $25/1000 queries on top of token costs
  # See: https://platform.openai.com/docs/models/gpt-4o-mini-search-preview
  WEB_SEARCH_MODEL = "gpt-4o-mini-search-preview"

  def initialize
    @client = OpenAI::Client.new(
      access_token: Rails.application.credentials.dig(:openai_api_key) || ENV["OPENAI_API_KEY"]
    )
  end

  # Standard chat without web search (for API-based responses)
  def chat(messages:, system_prompt:)
    api_messages = [{ role: "system", content: system_prompt }]
    api_messages += messages.map { |m| { role: m[:role], content: m[:content] } }

    response = @client.chat(
      parameters: {
        model: MODEL,
        messages: api_messages,
        max_tokens: 1024
      }
    )

    content = response.dig("choices", 0, "message", "content")
    tokens_used = response.dig("usage", "total_tokens") || 0

    {
      content: content || "I couldn't generate a response.",
      tokens_used: tokens_used,
      source: :api
    }
  rescue Faraday::Error => e
    Rails.logger.error("AiService API error: #{e.message}")
    {
      content: "I'm having trouble connecting right now. Please try again in a moment.",
      tokens_used: 0,
      source: :error
    }
  rescue StandardError => e
    Rails.logger.error("AiService unexpected error: #{e.message}")
    {
      content: "Something went wrong. Please try again.",
      tokens_used: 0,
      source: :error
    }
  end

  # Chat with web search enabled (for general Q&A)
  # Uses gpt-4o-mini-search-preview which has built-in web search capability
  # The model automatically searches when needed - no tools parameter required
  def chat_with_web_search(messages:, system_prompt:)
    Rails.logger.info("AiService: Starting web search with model #{WEB_SEARCH_MODEL}")

    api_messages = [{ role: "system", content: system_prompt }]
    api_messages += messages.map { |m| { role: m[:role], content: m[:content] } }

    # The search-preview model has built-in web search
    # web_search_options controls search behavior
    response = @client.chat(
      parameters: {
        model: WEB_SEARCH_MODEL,
        messages: api_messages,
        max_tokens: 1024,
        web_search_options: {
          search_context_size: "medium" # low, medium, or high
        }
      }
    )

    content = response.dig("choices", 0, "message", "content")
    tokens_used = response.dig("usage", "total_tokens") || 0

    Rails.logger.info("AiService: Web search completed successfully (#{tokens_used} tokens)")

    # Clean up the response - strip citations and truncate if needed
    clean_content = clean_web_search_response(content)

    {
      content: clean_content || "I couldn't generate a response.",
      tokens_used: tokens_used,
      source: :web_search
    }
  rescue Faraday::Error => e
    Rails.logger.error("AiService WEB SEARCH FAILED (Faraday): #{e.class} - #{e.message}")
    Rails.logger.error("AiService: Full error: #{e.inspect}")
    # Fallback to regular chat if web search fails
    Rails.logger.warn("AiService: FALLING BACK to regular chat without web search")
    chat(messages: messages, system_prompt: system_prompt)
  rescue StandardError => e
    Rails.logger.error("AiService WEB SEARCH FAILED (Standard): #{e.class} - #{e.message}")
    Rails.logger.error("AiService: Full error: #{e.inspect}")
    Rails.logger.error("AiService: Backtrace: #{e.backtrace.first(5).join("\n")}")
    # Fallback to regular chat on any error
    Rails.logger.warn("AiService: FALLING BACK to regular chat without web search")
    chat(messages: messages, system_prompt: system_prompt)
  end

  # Clean up web search response - strip citations, data dumps, and truncate
  # The search model adds citations and sometimes goes into repetitive loops
  def clean_web_search_response(content)
    return content if content.nil?

    # Remove markdown link citations: ([text](url))
    content = content.gsub(/\s*\(\[[\w\.\-]+\]\([^\)]+\)\)/, "")

    # Remove inline citations: [text](url)
    content = content.gsub(/\[[\w\.\-]+\]\([^\)]+\?utm_source=openai[^\)]*\)/, "")

    # Remove any remaining bare URLs with utm_source=openai
    content = content.gsub(/https?:\/\/[^\s\)]+\?utm_source=openai[^\s\)]*/, "")

    # Remove schedule dumps (## NFL Schedule followed by game listings)
    content = content.gsub(/##\s*NFL Schedule.*?(?=\n\n[A-Z]|\n\n\z|\z)/m, "")

    # Remove markdown headers that slipped through
    content = content.gsub(/^##\s+.+$/m, "")

    # Remove bullet point lists
    content = content.gsub(/^-\s+.+$/m, "")

    # Clean up multiple newlines
    content = content.gsub(/\n{3,}/, "\n\n")

    # Clean up any double spaces left behind
    content = content.gsub(/  +/, " ")

    # Clean up any orphaned parentheses
    content = content.gsub(/\(\s*\)/, "")

    content = content.strip

    # Truncate to reasonable length (the model sometimes loops)
    # Find a natural stopping point around 400 chars (about 60-80 words)
    # Look for a question mark (follow-up question) or period near the end
    if content.length > 600
      # Try to find a follow-up question (ends with ?)
      question_match = content[0..800].rindex("?")
      if question_match && question_match > 200
        content = content[0..question_match]
      else
        # Find the last complete sentence within 500 chars
        period_match = content[0..600].rindex(".")
        if period_match && period_match > 200
          content = content[0..period_match]
        else
          # Just truncate at word boundary
          content = content[0..500].sub(/\s+\S*$/, "") + "..."
        end
      end
    end

    content
  end

  # Hybrid: Get betting data from API context, then enrich with web search
  def chat_hybrid(messages:, system_prompt:, api_context:)
    # First, embed the API context in the system prompt
    enriched_prompt = system_prompt + "\n\n## BETTING DATA (from API):\n#{api_context}"

    # Then use web search to get additional context
    chat_with_web_search(messages: messages, system_prompt: enriched_prompt)
  end

  def self.system_prompt(context_data: nil)
    prompt = load_system_prompt
    prompt.gsub("{CONTEXT_DATA}", context_data || "No context data available.")
  end

  def self.load_system_prompt
    prompt_path = Rails.root.join("prompts", "system_prompt.md")
    if File.exist?(prompt_path)
      File.read(prompt_path)
    else
      default_system_prompt
    end
  end

  def self.default_system_prompt
    <<~PROMPT
      You are SportsBiff, a friendly and knowledgeable sports companion for serious fans.

      ## Your Personality
      - Conversational and opinionated, like a smart friend who follows sports closely
      - You care about the USER'S TEAMS first and foremost
      - Give "what matters" summaries, not data dumps
      - Be concise but insightful

      ## Important Rules
      1. ONLY use the data provided below - NEVER make up scores, stats, or facts
      2. If you don't have data on something, say "I don't have that information right now"
      3. Keep responses concise (under 200 words unless detail is needed)
      4. When discussing odds/betting, frame as "market intelligence" not advice
         - Say "markets favor..." or "the line suggests..." NOT "you should bet..."
         - Never guarantee outcomes or recommend specific bets

      ## Current Real-Time Data
      {CONTEXT_DATA}

      Use ONLY the data above. If asked about something not in this data, acknowledge you don't have it rather than guessing.
    PROMPT
  end
end
