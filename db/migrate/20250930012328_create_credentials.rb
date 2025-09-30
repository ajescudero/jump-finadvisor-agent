# db/migrate/20250929120000_create_credentials.rb
class CreateCredentials < ActiveRecord::Migration[7.2]
  def change
    create_table :credentials do |t|
      t.references :user, null: false, foreign_key: true
      t.string :provider, null: false
      t.text :access_token
      t.text :refresh_token
      t.datetime :expires_at
      t.timestamps
    end

    add_index :credentials, [:user_id, :provider], unique: true
  end
end
