class AiService
  MODEL = "gpt-4o-mini"

  def initialize
    @client = OpenAI::Client.new(
      access_token: Rails.application.credentials.dig(:openai_api_key) || ENV["OPENAI_API_KEY"]
    )
  end

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
      tokens_used: tokens_used
    }
  rescue Faraday::Error => e
    Rails.logger.error("AiService API error: #{e.message}")
    {
      content: "I'm having trouble connecting right now. Please try again in a moment.",
      tokens_used: 0
    }
  rescue StandardError => e
    Rails.logger.error("AiService unexpected error: #{e.message}")
    {
      content: "Something went wrong. Please try again.",
      tokens_used: 0
    }
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
