class HealthController < ApplicationController
  def show
    db_ok = ActiveRecord::Base.connection.active?
    redis_ok = ENV["REDIS_URL"].present?
    render json: { status: "ok", db: db_ok, redis: redis_ok }
  rescue => e
    render json: { status: "fail", error: e.message }, status: 500
  end
end
