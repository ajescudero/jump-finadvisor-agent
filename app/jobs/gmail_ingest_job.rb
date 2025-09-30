# app/jobs/gmail_ingest_job.rb (añade path real)
class GmailIngestJob < ApplicationJob
  queue_as :default

  def perform(user_id, max_results: 50)
    user = User.find(user_id)
    cred = Credential.find_by!(user_id: user.id, provider: "google")

    auth = Signet::OAuth2::Client.new(
      client_id: ENV.fetch("GOOGLE_CLIENT_ID"),
      client_secret: ENV.fetch("GOOGLE_CLIENT_SECRET"),
      access_token: cred.access_token,
      refresh_token: cred.refresh_token,
      token_credential_uri: "https://oauth2.googleapis.com/token"
    )
    refresh_if_needed!(auth, cred)

    service = Google::Apis::GmailV1::GmailService.new
    service.authorization = auth

    cap = ENV.fetch("MAX_INGEST_PER_RUN", max_results).to_i
    cap = max_results if cap <= 0 || cap > max_results

    msg_list = service.list_user_messages("me", max_results: cap)
    provider = EmbeddingProvider.provider

    Array(msg_list.messages).each do |m|
      full = service.get_user_message("me", m.id, format: "full")
      text = flatten_gmail(full)
      upsert_embedding!(user.id, "email", m.id, text, provider)
    end
  end

  private

  def refresh_if_needed!(auth, cred)
    if auth.expired?
      auth.refresh!
      cred.update!(
        access_token: auth.access_token,
        expires_at: Time.now + auth.expires_in.to_i
      )
    end
  end

  def flatten_gmail(msg)
    parts = (msg.payload.parts || [])
    bodies = parts.map { |p| Base64.decode64(p.body.data.to_s.tr("-_", "+/")) rescue "" }
    ([msg.snippet] + bodies).compact.join("\n")
  end

  def upsert_embedding!(user_id, kind, ref_id, text, provider)
    Embedding.upsert(
      { user_id: user_id, kind: kind, ref_id: ref_id, chunk: text, embedding: provider.embed_text(text) },
      unique_by: %i[user_id kind ref_id]
    )
  end
end
