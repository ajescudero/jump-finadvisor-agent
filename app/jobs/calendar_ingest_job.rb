# app/jobs/calendar_ingest_job.rb
class CalendarIngestJob < ApplicationJob
  queue_as :default

  MAX_INGEST = ENV.fetch("MAX_INGEST_PER_RUN", 200).to_i

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

    cap = [MAX_INGEST, max_results].min

    events = with_retries do
      svc.list_events(
        "primary",
        single_events: true,
        order_by: "startTime",
        time_min: time_min.iso8601,
        time_max: time_max.iso8601,
        max_results: cap
      )
    end

    Array(events.items).each do |ev|
      start_t = ev.start&.date_time || ev.start&.date
      end_t   = ev.end&.date_time || ev.end&.date
      text    = [
        ev.summary,
        ("from: #{start_t} to: #{end_t}" if start_t || end_t),
        ("location: #{ev.location}" if ev.location.present?),
        ("description: #{ev.description}" if ev.description.present?)
      ].compact.join("\n")

      # Persist as a Note for structured storage
      save_event_note_record!(user.id, ev, text, start_t)

      # Upsert embedding for semantic search
      upsert_embedding!(user.id, "event", ev.id, text, provider)
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

  def save_event_note_record!(user_id, ev, text, start_time)
    rec = Note.find_or_initialize_by(user_id: user_id, source: "google_calendar", ext_id: ev.id)
    rec.body_text      = text
    rec.created_at_ext = start_time if rec.respond_to?(:created_at_ext)
    rec.save!
  end

  def upsert_embedding!(user_id, kind, ref_id, text, provider)
    Embedding.upsert(
      { user_id: user_id, kind: kind, ref_id: ref_id, chunk: text, embedding: provider.embed_text(text) },
      unique_by: %i[user_id kind ref_id]
    )
  end
end
