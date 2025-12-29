class GenerateResponseJob < ApplicationJob
  queue_as :default

  def perform(chat_id, user_message_id)
    chat = Chat.find(chat_id)
    user_message = Message.find(user_message_id)

    # Build context and get AI response
    response = ResponseBuilder.new(chat: chat, user_message: user_message).build

    # Create the assistant message
    assistant_message = chat.messages.create!(
      role: "assistant",
      content: response[:content],
      tokens_used: response[:tokens_used]
    )

    # Update chat title if this is the first exchange
    update_chat_title(chat, user_message) if chat.messages.count <= 2

    # Broadcast the response via Turbo Streams
    Turbo::StreamsChannel.broadcast_replace_to(
      chat,
      target: "thinking",
      partial: "messages/message",
      locals: { message: assistant_message }
    )
  rescue StandardError => e
    Rails.logger.error("GenerateResponseJob failed: #{e.message}")

    # Broadcast error message
    Turbo::StreamsChannel.broadcast_replace_to(
      chat,
      target: "thinking",
      partial: "messages/error",
      locals: { error: "Sorry, I encountered an error. Please try again." }
    )
  end

  private

  def update_chat_title(chat, user_message)
    # Use first ~50 chars of user message as title
    title = user_message.content.truncate(50)
    chat.update(title: title)
  end
end
