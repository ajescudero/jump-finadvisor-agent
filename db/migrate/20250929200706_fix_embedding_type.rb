class FixEmbeddingType < ActiveRecord::Migration[7.2]
  def change
    change_column :embeddings, :embedding, :vector, limit: 1536
  end
end