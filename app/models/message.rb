class Message < ApplicationRecord
  belongs_to :chat

  ROLES = %w[user assistant].freeze

  validates :role, inclusion: { in: ROLES }
  validates :content, presence: true

  scope :chronological, -> { order(created_at: :asc) }

  def user?
    role == "user"
  end

  def assistant?
    role == "assistant"
  end
end
