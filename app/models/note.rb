# app/models/note.rb
class Note < ApplicationRecord
  belongs_to :user
  belongs_to :contact, optional: true

  validates :source, presence: true
  # ext_id can be nil for local notes; when present, enforce uniqueness per user+source
  validates :ext_id, uniqueness: { scope: [:user_id, :source] }, allow_nil: true
end
