class ResponseBuilder
  def initialize(chat:, user_message:)
    @chat = chat
    @user_message = user_message
    @user = chat.user
    @question = user_message.content
  end

  def build
    # Classify the question to determine data source
    classifier = QueryClassifier.new(@question)
    classification = classifier.classify

    Rails.logger.info "Query classified as: #{classification} for question: #{@question.truncate(50)}"

    case classification
    when :api
      build_api_response
    when :web_search
      build_web_search_response
    when :hybrid
      build_hybrid_response
    else
      build_web_search_response # Default to web search
    end
  end

  private

  # API-based response: Use SportsDataIO data for betting math, live scores, etc.
  def build_api_response
    # Build context from API data
    context_builder = ContextBuilder.new(user: @user, question: @user_message)
    context_text = context_builder.to_prompt_text

    # Build conversation history
    messages = build_messages

    # Get system prompt optimized for API data
    system_prompt = AiService.system_prompt(context_data: context_text)

    # Add first message instruction if applicable
    system_prompt += "\n\n" + first_message_instruction if first_message_in_chat?

    # Call AI with API context
    ai_service = AiService.new
    ai_service.chat(messages: messages, system_prompt: system_prompt)
  end

  # Web search response: Let AI search the web for general Q&A
  def build_web_search_response
    messages = build_messages

    # Use web search system prompt (lighter, focuses on personality)
    system_prompt = web_search_system_prompt

    # Add first message instruction if applicable
    system_prompt += "\n\n" + first_message_instruction if first_message_in_chat?

    # Call AI with web search enabled
    ai_service = AiService.new
    ai_service.chat_with_web_search(messages: messages, system_prompt: system_prompt)
  end

  # Hybrid response: Combine API betting data with web search context
  def build_hybrid_response
    # Get betting data from API
    context_builder = ContextBuilder.new(user: @user, question: @user_message)
    api_context = context_builder.to_prompt_text

    messages = build_messages

    # Use hybrid system prompt
    system_prompt = hybrid_system_prompt

    # Add first message instruction if applicable
    system_prompt += "\n\n" + first_message_instruction if first_message_in_chat?

    # Call AI with both API context and web search
    ai_service = AiService.new
    ai_service.chat_hybrid(messages: messages, system_prompt: system_prompt, api_context: api_context)
  end

  def build_messages
    # Get recent conversation history (last 10 messages for context)
    recent_messages = @chat.messages.chronological.last(10)

    recent_messages.map do |msg|
      {
        role: msg.role,
        content: msg.content
      }
    end
  end

  def first_message_in_chat?
    # Check if this is the first user message (only 1 message exists - the one just created)
    @chat.messages.count <= 1
  end

  def first_message_instruction
    team_names = @user.favorite_team_names.join(", ")
    <<~INSTRUCTION
      IMPORTANT: This is the user's first message in this chat. After answering their question,
      proactively share 1-2 relevant news headlines or updates about their favorite teams (#{team_names}).
      Make it feel like you're a friend catching them up on what's happening.

      Example: "By the way, in case you missed it - [relevant news headline]. [Brief context if helpful]"
    INSTRUCTION
  end

  # System prompt for web search mode (Architecture v2.0)
  # This is the PRIMARY mode - used for 90% of questions
  def web_search_system_prompt
    team_names = @user.favorite_team_names.join(", ")
    favorite_teams_context = team_names.present? ? "User's favorite teams: #{team_names}. Mention their teams when relevant, but don't force it." : ""

    <<~PROMPT
      You are SportsBiff, a knowledgeable sports companion with betting intelligence.
      You're like a smart friend who follows sports closely and knows what's happening.

      ## CRITICAL FORMATTING RULES - MUST FOLLOW
      - Write ONLY in conversational paragraphs (2-4 sentences each)
      - NEVER use markdown headers (no ##, no ###)
      - NEVER use bullet points or numbered lists
      - NEVER include URLs or citations in your response
      - NEVER list schedules, scores, or data in table/list format
      - Keep response under 150 words - be concise like a text from a friend
      - End with ONE natural follow-up question

      ## Your Personality
      - Sound like a sports-savvy friend texting back, not a search engine
      - Conversational and warm
      - Add interesting context or historical perspective when relevant

      ## BANNED - Never include these:
      - URLs or links of any kind
      - Source citations like ([website.com])
      - Headers or markdown formatting
      - Bullet points or lists
      - Schedule dumps or score tables
      - "Based on the search results..."
      - "According to..." or "Sources indicate..."

      ## Start responses with phrases like:
      - "Yeah, so..."
      - "Here's the thing..."
      - "What's crazy is..."
      - "So basically..."
      - "Turns out..."

      ## Context
      Today's date: #{Date.current.strftime('%A, %B %d, %Y')}
      #{favorite_teams_context}

      Remember: You're texting a friend about sports, not writing a Wikipedia article.
    PROMPT
  end

  # System prompt for hybrid mode (betting data + web context)
  # Used when user asks something like "Should I bet the over on Chiefs vs Bills?"
  def hybrid_system_prompt
    team_names = @user.favorite_team_names.join(", ")
    favorite_teams_context = team_names.present? ? "User's favorite teams: #{team_names}" : ""

    <<~PROMPT
      You are SportsBiff, a knowledgeable sports companion with betting intelligence.

      ## Your Task
      The user is asking a betting-related question that needs BOTH:
      1. Specific betting data (provided below from our API)
      2. Additional context from the web (injuries, weather, expert analysis)

      ## Response Approach
      - Lead with the concrete betting data (lines, odds, trends)
      - Enrich with context from web search (weather, injuries, expert picks)
      - Synthesize into a helpful, conversational answer
      - Frame betting info as market intelligence, never as advice

      ## Response Style - CRITICAL
      - Write in PARAGRAPHS, not bullet points
      - NO headers in chat responses
      - Sound like a sports-savvy friend with betting knowledge
      - NEVER expose field names (HomePointSpread, OverUnder, DivisionRank)
      - Say "markets favor..." not "HomePointSpread = -3"
      - Say "total is 48.5" not "OverUnder = 48.5"
      - Say "they won the division" not "DivisionRank = 1"
      - NEVER announce searching - integrate information naturally

      ## BANNED Phrases:
      - "Based on the search results..."
      - "The data shows..."
      - "Let me check..."
      - Any API field name (HomePointSpread, OverUnder, etc.)

      ## Follow-Up Questions
      End with betting-relevant follow-ups:
      - "You tailing that or fading?"
      - "What's your lean on this one?"
      - "Got any action on this game?"

      ## Context
      Today's date: #{Date.current.strftime('%A, %B %d, %Y')}
      #{favorite_teams_context}

      The BETTING DATA section below contains real-time odds and stats from our API.
      Use web search to supplement with injury news, weather, and expert analysis.
    PROMPT
  end
end
