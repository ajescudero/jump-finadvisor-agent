# db/seeds.rb

# Demo user for development/testing
u = User.find_or_create_by!(email: ENV.fetch("DEMO_USER_EMAIL", "dev@local.test"))

if Embedding.where(user: u).count == 0
  samples = [
    { kind: "note", ref_id: "sara-1", text: "Sara loves baseball and is interested in college savings." },
    { kind: "note", ref_id: "greg-1", text: "Greg wants to sell AAPL to rebalance his portfolio." },
    { kind: "message", ref_id: "team-1", text: "Quarterly All Team Meeting scheduled for Thursday at noon." }
  ]

  samples.each do |s|
    Embedding.create!(
      user: u,
      kind: s[:kind],
      ref_id: s[:ref_id],
      chunk: s[:text],
      embedding: EmbeddingProvider.embed_text(s[:text])
    )
  end
  puts "Seeded #{samples.size} sample embeddings for user ##{u.id}"
else
  puts "Embeddings already present for user ##{u.id}"
end

# -------------------------------------------------------
# Extra: run dummy ingest jobs (if they exist in the app)
# -------------------------------------------------------
begin
  GmailIngestJob.perform_now(u.id)
  CalendarIngestJob.perform_now(u.id)
  puts "Dummy ingest jobs seeded extra embeddings for user ##{u.id}"
rescue NameError => e
  puts "Skip ingest jobs: #{e.message}"
end

puts "Final embeddings count:"
puts Embedding.where(user_id: u.id).group(:kind).count.inspect
