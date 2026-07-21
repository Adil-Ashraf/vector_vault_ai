require "rails_helper"

RSpec.describe "POST /api/v1/query/ask", type: :request do
  subject(:make_request) { post "/api/v1/query/ask", params: params, headers: headers }

  let(:headers) { auth_headers }
  let(:params) { { query: "What is Ruby on Rails?" } }
  let(:fake_result) do
    { title: "General Knowledge", url: nil, answer: "Rails is a web framework.", context: "..." }
  end

  context "without an API key" do
    let(:headers) { {} }

    it "returns unauthorized" do
      make_request

      expect(response).to have_http_status(:unauthorized)
    end
  end

  context "with a valid API key" do
    context "when the query param is blank" do
      let(:params) { { query: "" } }

      it "returns a bad request error" do
        make_request

        expect(response).to have_http_status(:bad_request)
        expect(JSON.parse(response.body)).to include("error" => "Query parameter cannot be blank.")
      end
    end

    context "when the query is valid" do
      let(:fake_query_service) { instance_double(QueryService, process: fake_result) }

      before do
        allow(QueryService).to receive(:new).with(params[:query]).and_return(fake_query_service)
      end

      it "returns the query result" do
        make_request

        expect(response).to have_http_status(:ok)
        expect(JSON.parse(response.body)).to include("title" => "General Knowledge", "answer" => "Rails is a web framework.")
      end
    end

    context "when QueryService raises an error" do
      let(:fake_query_service) { instance_double(QueryService) }

      before do
        allow(QueryService).to receive(:new).with(params[:query]).and_return(fake_query_service)
        allow(fake_query_service).to receive(:process).and_raise(StandardError, "boom")
      end

      it "returns a generic error without leaking internal details" do
        make_request

        expect(response).to have_http_status(:internal_server_error)
        expect(JSON.parse(response.body)["error"]).not_to include("boom")
      end
    end
  end
end
