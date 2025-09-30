# app/jobs/calendar_ingest_job.rb
class CalendarIngestJob < ApplicationJob
  queue_as :default

  def perform(user_id, time_min: Time.now - 30.days, time_max: Time.now + 30.days, max_results: 100)
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

    svc = Google::Apis::CalendarV3::CalendarService.new
    svc.authorization = auth

    provider = EmbeddingProvider.provider

    cap = ENV.fetch("MAX_INGEST_PER_RUN", max_results).to_i
    cap = max_results if cap <= 0 || cap > max_results

    events = svc.list_events(
      "primary",
      single_events: true,
      order_by: "startTime",
      time_min: time_min.iso8601,
      time_max: time_max.iso8601,
      max_results: cap
    )

    Array(events.items).each do |ev|
      start_t = ev.start&.date_time || ev.start&.date
      end_t   = ev.end&.date_time || ev.end&.date
      text    = [
        ev.summary,
        ("from: #{start_t} to: #{end_t}" if start_t || end_t),
        ("location: #{ev.location}" if ev.location.present?),
        ("description: #{ev.description}" if ev.description.present?)
      ].compact.join("\n")

      upsert_embedding!(user.id, "event", ev.id, text, provider)
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

  def upsert_embedding!(user_id, kind, ref_id, text, provider)
    Embedding.upsert(
      { user_id: user_id, kind: kind, ref_id: ref_id, chunk: text, embedding: provider.embed_text(text) },
      unique_by: %i[user_id kind ref_id]
    )
  end
end
