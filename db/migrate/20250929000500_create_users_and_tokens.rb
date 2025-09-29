class CreateUsersAndTokens < ActiveRecord::Migration[7.2]
  def change
    create_table :users do |t|
      t.string  :email, null: false, index: { unique: true }

      # Google OAuth tokens
      t.text    :google_access_token
      t.text    :google_refresh_token
      t.datetime :google_expires_at
      t.string  :google_token_type
      t.string  :google_scope

      # HubSpot OAuth tokens
      t.text    :hubspot_access_token
      t.text    :hubspot_refresh_token
      t.datetime :hubspot_expires_at
      t.string  :hubspot_token_type
      t.string  :hubspot_scope

      t.timestamps
    end
  end
end
