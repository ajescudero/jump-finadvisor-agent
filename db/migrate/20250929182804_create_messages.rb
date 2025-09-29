class CreateMessages < ActiveRecord::Migration[7.1]
  def change
    create_table :messages do |t|
      t.references :user, null: false, foreign_key: true
      t.string  :source, null: false              # "gmail" | "hubspot" (future)
      t.string  :ext_id, null: false              # external message id
      t.string  :thread_id
      t.string  :subject
      t.string  :sender
      t.datetime :sent_at
      t.text    :body_text

      t.timestamps
    end
    add_index :messages, [:user_id, :source, :ext_id], unique: true
    add_index :messages, :thread_id
    add_index :messages, :sent_at
  end
end