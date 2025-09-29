class AddIvfflatIndexOnEmbeddings < ActiveRecord::Migration[7.2]
  disable_ddl_transaction!

  def up
    execute <<~SQL
      CREATE INDEX CONCURRENTLY index_embeddings_on_embedding_ivfflat_cosine
      ON embeddings
      USING ivfflat (embedding vector_cosine_ops)
      WITH (lists = 100);
    SQL
  end

  def down
    execute <<~SQL
      DROP INDEX CONCURRENTLY IF EXISTS index_embeddings_on_embedding_ivfflat_cosine;
    SQL
  end
end