require "rails_helper"

RSpec.describe AiService do
  subject(:service) { described_class.new("test-key") }

  describe "#split_text_into_chunks" do
    it "splits long text into multiple overlapping chunks" do
      text = ("Sentence number #{'x' * 50}. " * 200)

      chunks = service.split_text_into_chunks(text, 500, 100)

      expect(chunks).to be_an(Array)
      expect(chunks.size).to be > 1
      expect(chunks).to all(be_a(String))
    end

    it "returns a single chunk when the text is shorter than the chunk size" do
      chunks = service.split_text_into_chunks("Short text.", 2500, 500)

      expect(chunks).to eq(["Short text"])
    end
  end

  describe "#generate_embedding" do
    it "returns the embedding vector for a single input" do
      stub_request(:post, "https://api.openai.com/v1/embeddings")
        .with(body: hash_including(model: AiService::EMBEDDING_MODEL, input: ["hello"]))
        .to_return(
          status: 200,
          headers: { "Content-Type" => "application/json" },
          body: {
            data: [{ index: 0, embedding: [0.1, 0.2, 0.3] }]
          }.to_json
        )

      embedding = service.generate_embedding("hello")

      expect(embedding).to eq([0.1, 0.2, 0.3])
    end
  end

  describe "#generate_embeddings" do
    it "returns an empty array without making a request when given no texts" do
      embeddings = service.generate_embeddings([])

      expect(embeddings).to eq([])
      expect(WebMock).not_to have_requested(:post, "https://api.openai.com/v1/embeddings")
    end

    it "sends all chunks in a single batched request and preserves order" do
      stub = stub_request(:post, "https://api.openai.com/v1/embeddings")
        .with(body: hash_including(model: AiService::EMBEDDING_MODEL, input: %w[first second]))
        .to_return(
          status: 200,
          headers: { "Content-Type" => "application/json" },
          body: {
            data: [
              { index: 1, embedding: [9, 9] },
              { index: 0, embedding: [1, 1] }
            ]
          }.to_json
        )

      embeddings = service.generate_embeddings(%w[first second])

      expect(embeddings).to eq([[1, 1], [9, 9]])
      expect(stub).to have_been_requested.times(1)
    end
  end

  describe "#generate_answer" do
    it "returns the assistant message content" do
      stub_request(:post, "https://api.openai.com/v1/chat/completions")
        .to_return(
          status: 200,
          headers: { "Content-Type" => "application/json" },
          body: {
            choices: [{ message: { content: "42" } }]
          }.to_json
        )

      answer = service.generate_answer("What is the answer?")

      expect(answer).to eq("42")
    end
  end
end
