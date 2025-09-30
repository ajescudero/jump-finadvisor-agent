# config/initializers/sidekiq_cron.rb
# Schedule periodic ingest jobs (tune cron as needed)
if defined?(Sidekiq) && (Rails.env.production? || ENV["ENABLE_CRON"] == "true")
  require "sidekiq/cron/job"

  uid = User.first&.id
  if uid
    Sidekiq::Cron::Job.create(
      name: "Ingest Gmail every 15m",
      cron: "*/15 * * * *",
      class: "GmailIngestJob",
      args: [uid]
    )
    Sidekiq::Cron::Job.create(
      name: "Ingest Calendar every 30m",
      cron: "*/30 * * * *",
      class: "CalendarIngestJob",
      args: [uid]
    )
  end
end
