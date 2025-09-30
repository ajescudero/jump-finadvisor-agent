# app/models/message.rb
class Message < ApplicationRecord
  belongs_to :user

  validates :source, presence: true
  validates :ext_id, presence: true, uniqueness: { scope: [:user_id, :source] }
end
