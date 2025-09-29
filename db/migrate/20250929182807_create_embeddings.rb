class CreateEmbeddings < ActiveRecord::Migration[7.1]
  def change
    create_table :embeddings do |t|
      t.references :user, null: false, foreign_key: true
      t.string  :kind, null: false               # "message" | "note" | "contact"
      t.string  :ref_id, null: false             # references messages/notes/contacts id (as string)
      t.text    :chunk, null: false
      t.column :embedding, :vector, limit: 1536         # pgvector

      t.timestamps
    end
    add_index :embeddings, [:user_id, :kind, :ref_id], unique: true
    add_index :embeddings, :kind
  end
end