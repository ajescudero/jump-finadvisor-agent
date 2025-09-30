# lib/tasks/ingest.rake
namespace :ingest do
  desc "Ingest Gmail for a user (requires Google OAuth connected)"
  task :gmail, [:user_id] => :environment do |_, args|
    abort "Usage: bin/rails ingest:gmail[USER_ID]" unless args[:user_id]

    GmailIngestJob.perform_now(args[:user_id].to_i)
    puts "[ingest:gmail] Done."
  end

  desc "Ingest Calendar for a user (requires Google OAuth connected)"
  task :calendar, [:user_id] => :environment do |_, args|
    abort "Usage: bin/rails ingest:calendar[USER_ID]" unless args[:user_id]

    CalendarIngestJob.perform_now(args[:user_id].to_i)
    puts "[ingest:calendar] Done."
  end
end
