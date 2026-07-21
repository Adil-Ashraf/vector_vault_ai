require "rails_helper"

RSpec.describe QueryService do
  subject(:process_query) { described_class.new(query).process }

  let(:query) { "What is Ruby on Rails?" }
  let(:query_embedding) { Array.new(1536) { 0.0 } }
  let(:fake_ai_service) { instance_double(AiService) }

  before do
    allow(AiService).to receive(:new).and_return(fake_ai_service)
    allow(fake_ai_service).to receive(:generate_embedding).with(query).and_return(query_embedding)
  end

  context "when a matching document exists" do
    let!(:matching_embedding) { create(:text_embedding, title: "Rails Guide", url: "https://example.com/rails") }

    before do
      allow(TextEmbedding).to receive(:nearest_neighbors).and_return([matching_embedding])
    end

    context "and the context yields a valid answer" do
      before do
        allow(fake_ai_service).to receive(:generate_answer).and_return("Rails is a web framework.")
      end

      it "returns an answer grounded in the matched context" do
        result = process_query

        expect(result).to include(
          title: "Rails Guide",
          url: "https://example.com/rails",
          answer: "Rails is a web framework.",
          context: matching_embedding.content
        )
      end
    end

    context "but the context does not yield a valid answer" do
      before do
        allow(fake_ai_service).to receive(:generate_answer).and_return(
          "I didn’t find any valid context or additional knowledge to answer this question.",
          "Falling back to general knowledge."
        )
      end

      it "falls back to a general knowledge response" do
        result = process_query

        expect(result).to include(title: "General Knowledge", url: nil, answer: "Falling back to general knowledge.")
      end
    end
  end

  context "when no matching document exists" do
    before do
      allow(TextEmbedding).to receive(:nearest_neighbors).and_return([])
      allow(fake_ai_service).to receive(:generate_answer).and_return("General knowledge answer.")
    end

    it "returns a general knowledge response" do
      result = process_query

      expect(result).to include(title: "General Knowledge", url: nil, answer: "General knowledge answer.")
    end
  end
end
