class Api::V1::QueryController < ApplicationController
  def ask
    begin
      query = params[:query]
      if query.blank?
        return render json: { error: "Query parameter cannot be blank." }, status: :bad_request
      end

      service = AiService.new
      query_embedding = service.generate_embedding(query)
      nearest_neighbors = TextEmbedding.nearest_neighbors(:embedding, query_embedding, distance: "cosine")

      if nearest_neighbors.any?
        closest_result = nearest_neighbors.first

        # Construct improved prompt
        prompt = <<~PROMPT
          You are an intelligent assistant helping users answer questions based on the provided content.

          Context:
          #{closest_result.content}

          Question:
          #{query}

          Instructions:
          - Use the information in the provided context to answer the question as accurately as possible.
          - If the context does not contain relevant information, rely on your general knowledge to provide a helpful and accurate response.
          - If neither the context nor your knowledge allows you to answer the question meaningfully, respond with: "I didn’t find any valid context or additional knowledge to answer this question."

          Answer in a clear, concise, and user-friendly manner.
        PROMPT

        answer = service.generate_answer(prompt)
        render json: {
          title: closest_result.title,
          url: closest_result.url,
          answer: answer, 
          context: closest_result.content,
        }, status: :ok
      else
        render json: { message: "No relevant context found." }, status: :not_found
      end
    rescue StandardError => e
      render json: { error: "An unexpected error occurred: #{e.message}" }, status: :internal_server_error
    end
  end
end
