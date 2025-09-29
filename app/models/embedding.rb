class Embedding < ApplicationRecord
  belongs_to :user
  has_neighbors :embedding
  validates :kind, :ref_id, :chunk, :embedding, presence: true
  validates :ref_id, uniqueness: { scope: [:user_id, :kind] }
end
