# app/jobs/gmail_ingest_job.rb
class GmailIngestJob < ApplicationJob
  queue_as :default

  def perform(user_id)
    user = User.find(user_id)

    # Dummy payload (simulating emails)
    emails = [
      { id: "m1", subject: "Welcome!", body: "Thanks for joining Jump Finadvisor." },
      { id: "m2", subject: "Meeting tomorrow", body: "Don't forget our call at 10am." }
    ]

    provider = EmbeddingProvider.provider

    emails.each do |mail|
      text = "#{mail[:subject]}\n#{mail[:body]}"

      record = Embedding.find_or_initialize_by(
        user_id: user.id,
        kind: "email",
        ref_id: mail[:id]
      )
      record.chunk = text
      record.embedding = provider.embed_text(text)
      record.save!
    end
  end
end
