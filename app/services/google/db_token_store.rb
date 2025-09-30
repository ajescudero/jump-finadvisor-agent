# app/services/google/db_token_store.rb
# A minimal token store that persists Google OAuth tokens in the credentials table.
# Compatible with Google::Auth::UserAuthorizer API (expects #load, #store, #delete).

class Google::DbTokenStore
  # Load token JSON string for a given id (string or integer).
  # Return nil if not found, as googleauth expects.
  def load(id)
    cred = Credential.find_by(user_id: id.to_i, provider: "google")
    return nil unless cred&.access_token

    data = {
      "access_token"  => cred.access_token,
      "refresh_token" => cred.refresh_token,
      "expiry"        => cred.expires_at&.iso8601
    }.compact

    JSON.generate(data)
  end

  # Store token JSON string for a given id.
  def store(id, token_json)
    data = JSON.parse(token_json.to_s)

    cred = Credential.find_or_initialize_by(user_id: id.to_i, provider: "google")
    cred.access_token  = data["access_token"].presence
    # Only overwrite refresh_token if provided; Google often omits it on refresh
    cred.refresh_token = data["refresh_token"].presence || cred.refresh_token
    cred.expires_at    = begin
      v = data["expiry"]
      v.present? ? Time.iso8601(v.to_s) : nil
    rescue ArgumentError
      nil
    end
    cred.save!
  end

  # Delete stored token for a given id.
  def delete(id)
    Credential.where(user_id: id.to_i, provider: "google").delete_all
  end
end
