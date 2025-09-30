class HealthController < ApplicationController
  def show
    checks = {}

    # DB connectivity
    ActiveRecord::Base.connection.execute("SELECT 1")
    checks[:db] = "ok"

    # pgvector extension present
    vector_ok = ActiveRecord::Base.connection
      .execute("SELECT EXISTS (SELECT 1 FROM pg_extension WHERE extname='vector')")
      .values.dig(0, 0)
    checks[:vector] = (vector_ok ? "ok" : "missing")

    # Redis / Sidekiq
    checks[:redis] = (Sidekiq.redis(&:info) ? "ok" : "fail") rescue "fail"

    render json: { status: "ok", checks: checks }
  end
end
