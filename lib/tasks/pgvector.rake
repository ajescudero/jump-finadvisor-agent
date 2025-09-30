require 'uri'
require 'cgi'

namespace :pgvector do
  desc "Check pgvector extension and ivfflat index"
  task check: :environment do
    # Print environment diagnostics first so users get help even if connection fails
    begin
      db_url = ENV["DATABASE_URL"].to_s
      if db_url.empty?
        puts "DATABASE_URL is not set"
      else
        uri = URI.parse(db_url)
        user = uri.user.to_s
        host = uri.host.to_s
        port = uri.port
        db   = uri.path.to_s.sub(%r{^/}, '')
        sslmode = (CGI.parse(uri.query.to_s)["sslmode"]&.first rescue nil)

        masked_user = user.sub(/(.{0,2}).*(.{0,2})/) { |m| ($1 || "")+"***"+($2 || "") }
        puts "DB host=#{host} port=#{port} db=#{db} user=#{masked_user} sslmode=#{sslmode || '(default)'}"
        puts "PREPARED_STATEMENTS=#{ENV.fetch('PREPARED_STATEMENTS', '(unset)')} RAILS_ENV=#{ENV['RAILS_ENV'] || 'development'}"

        pooler = host.include?("pooler.supabase.com") || port == 6543
        direct = !pooler && (port == 5432 || host.include?(".supabase.com"))

        if pooler
          # Supabase pgBouncer constraints
          if user == "postgres"
            puts "WARN: Using generic 'postgres' user on Supabase pooler will fail. Use project-specific 'postgres.<project-ref>'."
          elsif user !~ /^postgres\.[a-z0-9]+$/
            puts "WARN: Supabase pooler expects username like 'postgres.<project-ref>'. Current user '#{user}'."
          end
          if ENV.fetch("PREPARED_STATEMENTS", "false").downcase != "false"
            puts "WARN: PREPARED_STATEMENTS must be false when using the Supabase pooler (pgBouncer)."
          end
        elsif direct
          if ENV.fetch("PREPARED_STATEMENTS", "false").downcase != "true"
            puts "WARN: Direct Postgres connections should set PREPARED_STATEMENTS=true for best compatibility."
          end
        end

        if sslmode.nil?
          puts "INFO: Consider adding sslmode=require to DATABASE_URL when connecting to cloud Postgres."
        end
      end
    rescue => diag_err
      puts "[pgvector:check] Warning: could not parse DATABASE_URL for diagnostics: #{diag_err.message}"
    end

    begin
      conn = ActiveRecord::Base.connection

      ext = conn.execute("SELECT extname FROM pg_extension WHERE extname='vector'").values.any?
      puts "pgvector extension: #{ext ? 'OK' : 'MISSING'}"

      idx = conn.execute("SELECT indexname FROM pg_indexes WHERE indexname ILIKE '%ivfflat%'").values.any?
      puts "ivfflat index:     #{idx ? 'OK' : 'MISSING'}"

      dim = conn.execute(<<~SQL).values.first&.first
        SELECT atttypmod FROM pg_attribute
        WHERE attrelid = 'embeddings'::regclass
          AND attname  = 'embedding'
          AND NOT attisdropped
      SQL
      if dim
        puts "embedding dimension: #{dim - 4} (typmod=#{dim})"
      else
        puts "embedding dimension: UNKNOWN"
      end
    rescue ActiveRecord::ConnectionNotEstablished, PG::ConnectionBad => e
      puts "[pgvector:check] Could not connect to the database."
      puts "Error: #{e.message}"
      puts
      puts "Hints:"
      puts "- If you're using Supabase pooler (port 6543), ensure DATABASE_URL uses the project-specific user 'postgres.<project-ref>' and PREPARED_STATEMENTS=false."
      puts "- If connecting directly (port 5432), use the non-pooler host and set PREPARED_STATEMENTS=true."
      puts "- Current RAILS_ENV=#{ENV['RAILS_ENV'] || 'development'}"
      puts "- Current PREPARED_STATEMENTS=#{ENV['PREPARED_STATEMENTS'] || '(unset)'}"
      exit 1
    end
  end
end
