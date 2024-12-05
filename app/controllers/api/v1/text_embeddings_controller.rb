class Api::V1::TextEmbeddingsController < ApplicationController
  def create
    service = AiService.new
    course_name = params[:course_name]
    course_description = params[:course_description]
    course_category = params[:course_category]
    content = params[:content]

    # Split content into chunks and generate embeddings
    embeddings = []
    service.split_text_into_chunks(content).each do |chunk|
      embedding = service.generate_embedding(chunk)
      embeddings << TextEmbedding.create!(
        content: chunk,
        embedding: embedding,
        course_name: course_name,
        course_description: course_description,
        course_category: course_category
      )
    end

    render json: { message: "#{embeddings.size} chunks embedded successfully." }, status: :created
  rescue => e
    render json: { error: e.message }, status: :unprocessable_entity
  end
end
