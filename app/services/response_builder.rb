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
      This is the user's first message in this chat. Their favorite teams are: #{team_names}.
      Answer their question first, then optionally add one relevant news item about their teams if it's genuinely interesting.
      Do NOT add filler like "By the way..." or rhetorical questions.
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
      - **Use bullet points and structure** for stats and multiple data points
      - **Lead with the key answer** in bold or as a clear opening line
      - Break down information into scannable bullet points
      - Use bold for key numbers and names
      - Keep response under 200 words total
      - NEVER include URLs or citations
      - NEVER end with rhetorical questions like "Did you catch...?" or "What do you think?"

      ## Response Format Example
      **Marvin Harrison Jr.** had a solid rookie season with the Cardinals:
      - **Receiving:** 1,012 yards on 79 catches
      - **Touchdowns:** 8 TDs
      - **Highlights:** Strong chemistry with Kyler Murray

      ## Your Personality
      - Sound like a sports-savvy friend, not a search engine
      - Conversational but structured
      - Give the facts clearly, then add brief context if relevant

      ## BANNED - Never include these:
      - URLs or links of any kind
      - Source citations like ([website.com])
      - Rhetorical questions at the end
      - "Did you catch any games?" or similar
      - "Based on the search results..."
      - "According to..." or "Sources indicate..."
      - Weather information unless specifically asked
      - Off-topic tangents

      ## Context
      Today's date: #{Date.current.strftime('%A, %B %d, %Y')}
      #{favorite_teams_context}

      Answer ONLY what was asked. Structure with bullet points. No fluff.
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

      ## CRITICAL FORMATTING RULES
      - **Use bullet points and structure** for odds, stats, and multiple data points
      - **Lead with the key answer** in bold
      - Break down betting info into scannable bullet points
      - Keep response under 200 words
      - Frame betting info as market intelligence, never as advice
      - NEVER end with rhetorical questions

      ## Response Format Example
      **Chiefs -3** looks interesting:
      - **Line:** Opened at -2.5, now -3
      - **Total:** 48.5 (sharp money on under)
      - **Key factor:** Mahomes 8-2 ATS as home favorite

      ## BANNED:
      - URLs or citations
      - Rhetorical questions at the end
      - "What's your lean?" or "You tailing?"
      - Field names (HomePointSpread, OverUnder, DivisionRank)
      - "Based on the search results..."

      ## Natural Language
      - Say "markets favor..." not "HomePointSpread = -3"
      - Say "total is 48.5" not "OverUnder = 48.5"
      - Say "they won the division" not "DivisionRank = 1"

      ## Context
      Today's date: #{Date.current.strftime('%A, %B %d, %Y')}
      #{favorite_teams_context}

      The BETTING DATA section below contains real-time odds and stats from our API.
      Use web search to supplement with injury news and expert analysis.
    PROMPT
  end
end
