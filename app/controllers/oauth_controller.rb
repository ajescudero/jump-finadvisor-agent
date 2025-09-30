# app/controllers/oauth_controller.rb
require "googleauth"
require "google/apis/gmail_v1"
require "google/apis/calendar_v3"

class OauthController < ApplicationController
  def google_start
    url = google_authorizer.get_authorization_url(
      base_url: request.base_url, # e.g. http://localhost:3000
      user_id:  current_user.id.to_s
    )

    # (Optional) safety check: only allow Google OAuth endpoints
    uri = URI.parse(url)
    unless uri.host&.end_with?("google.com")
      raise "Unsafe OAuth redirect host: #{uri.host}"
    end

    # Allow redirect to another host (Google)
    redirect_to url, allow_other_host: true
  end

  def google_callback
    credentials = google_authorizer.get_and_store_credentials_from_code(
      user_id: current_user.id.to_s,
      code: params[:code],
      base_url: request.base_url
    )

    cred = Credential.find_or_initialize_by(user_id: current_user.id, provider: "google")
    cred.access_token  = credentials.access_token
    cred.refresh_token = credentials.refresh_token if credentials.refresh_token.present?
    cred.expires_at    = Time.at(credentials.expires_at) rescue cred.expires_at
    cred.save!

    redirect_to root_path, notice: "Google connected"
  rescue => e
    redirect_to root_path, alert: "OAuth error: #{e.message}"
  end

  private

  def google_authorizer
    client_id = Google::Auth::ClientId.new(
      ENV.fetch("GOOGLE_CLIENT_ID"),
      ENV.fetch("GOOGLE_CLIENT_SECRET")
    )
    scopes = [
      Google::Apis::GmailV1::AUTH_GMAIL_READONLY,
      Google::Apis::CalendarV3::AUTH_CALENDAR_READONLY
    ]
    token_store = Google::DbTokenStore.new
    Google::Auth::UserAuthorizer.new(client_id, scopes, token_store)
  end

  # Build absolute callback URL from the current request to avoid mismatches
  def callback_absolute_url
    # request.base_url preserves http/https, host, and port from the incoming request
    request.base_url + auth_google_callback_path
  end

  # For dev: use the first user
  def current_user
    User.first || User.create!(email: ENV.fetch("DEMO_USER_EMAIL", "demo@jump.local"))
  end
end
