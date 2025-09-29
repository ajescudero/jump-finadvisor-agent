class Embedding < ApplicationRecord
  belongs_to :user
  validates :kind, :ref_id, :chunk, presence: true
end
