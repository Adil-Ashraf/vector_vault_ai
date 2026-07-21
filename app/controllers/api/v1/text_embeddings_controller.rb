class Api::V1::TextEmbeddingsController < ApplicationController
  before_action :validate_params, only: [:create]

  def create
    service = AiService.new
    title = params[:title]
    url = params[:url]
    content = params[:content]

    chunks = service.split_text_into_chunks(content)
    chunk_embeddings = service.generate_embeddings(chunks)

    records = chunks.zip(chunk_embeddings).map do |chunk, embedding|
      TextEmbedding.create!(title: title, url: url, content: chunk, embedding: embedding)
    end

    render json: { message: "#{records.size} chunks embedded successfully." }, status: :created
  rescue StandardError => e
    Rails.logger.error("TextEmbeddingsController#create failed: #{e.class}: #{e.message}")
    render json: { error: "Failed to process embeddings. Please try again later." }, status: :unprocessable_entity
  end

  private

  def text_embedding_params
    params.permit(:title, :url, :content)
  end

  def validate_params
    missing_params = []
    missing_params << "title" if text_embedding_params[:title].blank?
    missing_params << "url" if text_embedding_params[:url].blank?
    missing_params << "content" if text_embedding_params[:content].blank?

    return if missing_params.empty?

    render json: { error: "Missing required parameters: #{missing_params.join(', ')}" }, status: :unprocessable_entity
  end
end
