module ApiAuthentication
  def auth_headers
    { "X-API-Key" => ENV.fetch("API_KEY") }
  end
end

RSpec.configure do |config|
  config.include ApiAuthentication, type: :request
end
