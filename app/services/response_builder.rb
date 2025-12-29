class ResponseBuilder
  def initialize(chat:, user_message:)
    @chat = chat
    @user_message = user_message
    @user = chat.user
  end

  def build
    # Build personalized context based on user's teams and the question
    context_builder = ContextBuilder.new(user: @user, question: @user_message)
    context_text = context_builder.to_prompt_text

    # Build conversation history
    messages = build_messages

    # Get system prompt with injected context
    system_prompt = AiService.system_prompt(context_data: context_text)

    # If this is the first message in a new chat, add instruction to share news
    if first_message_in_chat?
      system_prompt += "\n\n" + first_message_instruction
    end

    # Call AI
    ai_service = AiService.new
    ai_service.chat(messages: messages, system_prompt: system_prompt)
  end

  private

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
      proactively share 1-2 relevant news headlines or updates about their favorite teams (#{team_names})
      from the RECENT NEWS section above. Make it feel like you're a friend catching them up on what's happening.

      Example: "By the way, in case you missed it - [relevant news headline]. [Brief context if helpful]"
    INSTRUCTION
  end
end
