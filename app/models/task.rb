class Task < ApplicationRecord
  belongs_to :user
  enum status: { pending: 0, running: 1, done: 2, failed: 3 }
  validates :title, presence: true
end
