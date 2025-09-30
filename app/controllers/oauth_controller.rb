# app/controllers/oauth_controller.rb
class OauthController < ApplicationController
  # Start Google OAuth flow
  def google_start
    client_id     = Google::Auth::ClientId.new(ENV["GOOGLE_CLIENT_ID"], ENV["GOOGLE_CLIENT_SECRET"])
    token_store   = Google::Auth::Stores::FileTokenStore.new(file: Rails.root.join("tmp", "tokens.yml"))
    authorizer    = Google::Auth::UserAuthorizer.new(client_id, scopes, token_store)
    user_id       = current_user_id # replace with your user logic
    redirect_to authorizer.get_authorization_url(base_url: callback_url, user_id: user_id)
  end

  # OAuth callback
  def google_callback
    client_id   = Google::Auth::ClientId.new(ENV["GOOGLE_CLIENT_ID"], ENV["GOOGLE_CLIENT_SECRET"])
    token_store = Google::Auth::Stores::FileTokenStore.new(file: Rails.root.join("tmp", "tokens.yml"))
    authorizer  = Google::Auth::UserAuthorizer.new(client_id, scopes, token_store)
    user_id     = current_user_id
    credentials = authorizer.get_and_store_credentials_from_code(
      user_id: user_id, code: params[:code], base_url: callback_url
    )

    cred = Credential.find_or_initialize_by(user_id: user_id, provider: "google")
    cred.access_token  = credentials.access_token
    cred.refresh_token = credentials.refresh_token if credentials.refresh_token.present?
    cred.expires_at    = Time.at(credentials.expires_at) if credentials.expires_at
    cred.save!

    redirect_to root_path, notice: "Google connected"
  end

  private

  def scopes
    [
      Google::Apis::GmailV1::AUTH_GMAIL_READONLY,
      Google::Apis::CalendarV3::AUTH_CALENDAR_READONLY
    ]
  end

  def callback_url
    auth_google_callback_url
  end

  def current_user_id
    # Replace with your auth; for dev use the demo user:
    User.first!.id
  end
end
