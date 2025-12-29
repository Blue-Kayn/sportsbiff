class MessagesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_chat

  def create
    unless current_user.can_query?
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: turbo_stream.append(
            "messages",
            partial: "messages/rate_limit_error"
          )
        end
        format.html { redirect_to @chat, alert: "Daily query limit reached" }
      end
      return
    end

    @user_message = @chat.messages.create!(
      role: "user",
      content: message_params[:content]
    )

    current_user.increment_query_count!

    respond_to do |format|
      format.turbo_stream do
        # First, stream the user message
        render turbo_stream: [
          turbo_stream.append("messages", partial: "messages/message", locals: { message: @user_message }),
          turbo_stream.replace("message_form", partial: "messages/form", locals: { chat: @chat, message: Message.new }),
          turbo_stream.append("messages", partial: "messages/thinking")
        ]
      end
      format.html { redirect_to @chat }
    end

    # Generate AI response in background
    GenerateResponseJob.perform_later(@chat.id, @user_message.id)
  end

  private

  def set_chat
    @chat = current_user.chats.find(params[:chat_id])
  end

  def message_params
    params.require(:message).permit(:content)
  end
end
