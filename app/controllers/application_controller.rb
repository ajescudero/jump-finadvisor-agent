class ApplicationController < ActionController::Base
  # Protect write endpoints with a simple header token
  before_action :require_api_token, if: -> {
    request.post? && request.path.start_with?("/embeddings")
  }

  private

  def require_api_token
    expected = ENV["API_TOKEN"].to_s
    return if expected.blank? # disabled
    provided = request.headers["X-API-TOKEN"].to_s
    provided = params[:api_token].to_s if provided.blank? # allow form param for HTML forms
    head :unauthorized unless ActiveSupport::SecurityUtils.secure_compare(provided, expected)
  end
end
