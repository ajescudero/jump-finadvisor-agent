# db/migrate/XXXXXXXXXXXX_add_unique_index_to_embeddings_on_user_kind_ref.rb
class AddUniqueIndexToEmbeddingsOnUserKindRef < ActiveRecord::Migration[7.2]
  # For large tables in Postgres, prefer concurrent index creation to avoid long locks.
  # NOTE: "algorithm: :concurrently" requires `disable_ddl_transaction!` and Postgres.
  disable_ddl_transaction!

  def up
    # If an index with the same columns already exists, skip gracefully.
    unless index_exists?(:embeddings, [:user_id, :kind, :ref_id], unique: true)
      add_index :embeddings, [:user_id, :kind, :ref_id],
                unique: true,
                name: "index_embeddings_on_user_kind_ref",
                algorithm: :concurrently
    end
  end

  def down
    if index_exists?(:embeddings, [:user_id, :kind, :ref_id], name: "index_embeddings_on_user_kind_ref")
      remove_index :embeddings, name: "index_embeddings_on_user_kind_ref", algorithm: :concurrently
    end
  end
end
