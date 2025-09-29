class CreateNotes < ActiveRecord::Migration[7.1]
  def change
    create_table :notes do |t|
      t.references :user, null: false, foreign_key: true
      t.string  :source, null: false             # "hubspot" | "gmail" | "system"
      t.string  :ext_id
      t.references :contact, foreign_key: true
      t.text    :body_text
      t.datetime :created_at_ext                 # external creation time

      t.timestamps
    end
    add_index :notes, [:user_id, :source, :ext_id], unique: true
    add_index :notes, :created_at_ext
  end
end