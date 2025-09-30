# lib/tasks/ingest.rake
namespace :ingest do
  desc "Ingest dummy Gmail for user_id"
  task :gmail, [:user_id] => :environment do |_, args|
    abort "Usage: bin/rails ingest:gmail[USER_ID]" unless args[:user_id]
    puts "[ingest:gmail] Enqueuing GmailIngestJob for user_id=#{args[:user_id]}"
    GmailIngestJob.perform_now(args[:user_id].to_i)
    puts "[ingest:gmail] Done."
  end

  desc "Ingest dummy Calendar for user_id"
  task :calendar, [:user_id] => :environment do |_, args|
    abort "Usage: bin/rails ingest:calendar[USER_ID]" unless args[:user_id]
    puts "[ingest:calendar] Enqueuing CalendarIngestJob for user_id=#{args[:user_id]}"
    CalendarIngestJob.perform_now(args[:user_id].to_i)
    puts "[ingest:calendar] Done."
  end

  desc "Ingest both Gmail and Calendar (dummy) for user_id"
  task :all, [:user_id] => :environment do |_, args|
    abort "Usage: bin/rails ingest:all[USER_ID]" unless args[:user_id]
    Rake::Task["ingest:gmail"].invoke(args[:user_id])
    Rake::Task["ingest:calendar"].reenable
    Rake::Task["ingest:calendar"].invoke(args[:user_id])
  end
end
