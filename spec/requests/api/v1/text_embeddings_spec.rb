require "rails_helper"

RSpec.describe "POST /api/v1/text_embeddings", type: :request do
  subject(:make_request) { post "/api/v1/text_embeddings", params: params, headers: headers }

  let(:headers) { auth_headers }
  let(:params) { { title: "Rails Guide", url: "https://example.com/rails", content: "Rails is great. " * 20 } }
  let(:fake_ai_service) { instance_double(AiService) }
  let(:chunks) { ["Rails is great.", "It ships with sensible defaults."] }
  let(:chunk_embeddings) { [Array.new(1536) { 0.1 }, Array.new(1536) { 0.2 }] }

  before do
    allow(AiService).to receive(:new).and_return(fake_ai_service)
    allow(fake_ai_service).to receive(:split_text_into_chunks).with(params[:content]).and_return(chunks)
    allow(fake_ai_service).to receive(:generate_embeddings).with(chunks).and_return(chunk_embeddings)
  end

  context "without an API key" do
    let(:headers) { {} }

    it "returns unauthorized" do
      make_request

      expect(response).to have_http_status(:unauthorized)
    end
  end

  context "with a valid API key" do
    context "when required params are missing" do
      let(:params) { { title: "", url: "", content: "" } }

      it "returns an unprocessable entity error listing the missing params" do
        make_request

        expect(response).to have_http_status(:unprocessable_entity)
        expect(JSON.parse(response.body)["error"]).to include("title", "url", "content")
      end
    end

    context "when params are valid" do
      it "generates embeddings for all chunks in a single batched call" do
        expect(fake_ai_service).to receive(:generate_embeddings).with(chunks).once.and_return(chunk_embeddings)

        make_request
      end

      it "persists one TextEmbedding record per chunk" do
        expect { make_request }.to change(TextEmbedding, :count).by(chunks.size)
      end

      it "returns a success message with the chunk count" do
        make_request

        expect(response).to have_http_status(:created)
        expect(JSON.parse(response.body)).to eq("message" => "2 chunks embedded successfully.")
      end
    end

    context "when embedding generation fails" do
      before do
        allow(fake_ai_service).to receive(:generate_embeddings).and_raise(StandardError, "openai down")
      end

      it "returns a generic error without leaking internal details" do
        make_request

        expect(response).to have_http_status(:unprocessable_entity)
        expect(JSON.parse(response.body)["error"]).not_to include("openai down")
      end
    end
  end
end
