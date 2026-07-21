class ApplicationController < ActionController::API
  before_action :authenticate_api_key!

  private

  def authenticate_api_key!
    return if ActiveSupport::SecurityUtils.secure_compare(provided_api_key.to_s, expected_api_key.to_s)

    render json: { error: "Unauthorized" }, status: :unauthorized
  end

  def provided_api_key
    request.headers["X-API-Key"]
  end

  def expected_api_key
    ENV.fetch("API_KEY")
  end
end
