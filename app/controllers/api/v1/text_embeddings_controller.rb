class Api::V1::TextEmbeddingsController < ApplicationController
  before_action :validate_params, only: [:create]

  def create
    service = AiService.new
    title = params[:title]
    url = params[:url]
    content = params[:content]

    # Split content into chunks and generate embeddings
    embeddings = []
    service.split_text_into_chunks(content).each do |chunk|
      embedding = service.generate_embedding(chunk)
      embeddings << TextEmbedding.create!(
        title: title,
        url: url,
        content: chunk,
        embedding: embedding
      )
    end

    render json: { message: "#{embeddings.size} chunks embedded successfully." }, status: :created
  rescue => e
    render json: { error: e.message }, status: :unprocessable_entity
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
