# app/jobs/calendar_ingest_job.rb
class CalendarIngestJob < ApplicationJob
  queue_as :default

  def perform(user_id)
    user = User.find(user_id)

    # Dummy payload (simulating calendar events)
    events = [
      { id: "e1", title: "Client kickoff", starts_at: "2025-10-01 10:00", ends_at: "2025-10-01 11:00" },
      { id: "e2", title: "Quarterly review", starts_at: "2025-10-03 15:30", ends_at: "2025-10-03 16:00" }
    ]

    provider = EmbeddingProvider.provider

    events.each do |ev|
      text = "#{ev[:title]}\nfrom: #{ev[:starts_at]} to: #{ev[:ends_at]}"

      record = Embedding.find_or_initialize_by(
        user_id: user.id,
        kind: "event",
        ref_id: ev[:id]
      )
      record.chunk = text
      record.embedding = provider.embed_text(text)
      record.save!
    end
  end
end
