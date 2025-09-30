# app/jobs/gmail_ingest_job.rb (añade path real)
class GmailIngestJob < ApplicationJob
  queue_as :default

  MAX_INGEST = ENV.fetch("MAX_INGEST_PER_RUN", 200).to_i

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

    cap = [MAX_INGEST, max_results].min

    msg_list = with_retries { service.list_user_messages("me", max_results: cap) }
    provider = EmbeddingProvider.provider

    Array(msg_list.messages).each do |m|
      full = with_retries { service.get_user_message("me", m.id, format: "full") }
      text = flatten_gmail(full)

      # Persist structured message for RAG/debugging
      headers = extract_headers(full)
      save_message_record!(user.id, full, text, headers)

      # Upsert embedding for semantic search
      upsert_embedding!(user.id, "email", m.id, text, provider)
    end
  end

  private

  def with_retries
    tries = 0
    begin
      yield
    rescue Google::Apis::RateLimitError, Google::Apis::ServerError
      tries += 1
      raise if tries > 3
      sleep(2 ** tries)
      retry
    end
  end

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

  # Extract selected headers (case-insensitive) into a hash
  def extract_headers(msg)
    hdrs = (msg.payload.headers || [])
    out = {}
    hdrs.each do |h|
      name = h.name.to_s.downcase
      case name
      when "subject" then out[:subject] = h.value.to_s
      when "from"    then out[:from]    = h.value.to_s
      when "date"    then out[:date]    = h.value.to_s
      end
    end
    out
  end

  def save_message_record!(user_id, full, text, headers)
    sent_at = begin
      Time.parse(headers[:date]) if headers[:date].present?
    rescue ArgumentError
      nil
    end

    rec = Message.find_or_initialize_by(user_id: user_id, source: "gmail", ext_id: full.id)
    rec.thread_id = full.thread_id if rec.respond_to?(:thread_id)
    rec.subject   = headers[:subject]
    rec.sender    = headers[:from]
    rec.sent_at   = sent_at
    rec.body_text = text
    rec.save!
  end

  def upsert_embedding!(user_id, kind, ref_id, text, provider)
    Embedding.upsert(
      { user_id: user_id, kind: kind, ref_id: ref_id, chunk: text, embedding: provider.embed_text(text) },
      unique_by: %i[user_id kind ref_id]
    )
  end
end
