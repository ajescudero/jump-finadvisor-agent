class Embedding < ApplicationRecord
  belongs_to :user
  has_neighbors :embedding

  # We store the original text in `chunk`. Provide `content` as an alias
  # so code like `Embedding.pluck(:content)` works without a DB column rename.
  alias_attribute :content, :chunk

  validates :kind, :ref_id, :chunk, :embedding, presence: true
  validates :ref_id, uniqueness: { scope: [:user_id, :kind] }
end
