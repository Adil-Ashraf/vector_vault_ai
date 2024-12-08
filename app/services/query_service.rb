class QueryService
  def initialize(query)
    @query = query
    @service = AiService.new
  end

  def process
    query_embedding = generate_embedding(@query)
    nearest_neighbors = find_nearest_neighbors(query_embedding)

    if nearest_neighbors.any?
      closest_result = nearest_neighbors.first
      response = generate_answer_with_context(closest_result)
      return response if valid_context_answer?(response)

      generate_general_knowledge_response
    else
      generate_general_knowledge_response
    end
  end

  private

  def generate_embedding(text)
    @service.generate_embedding(text)
  end

  def find_nearest_neighbors(query_embedding)
    TextEmbedding.nearest_neighbors(:embedding, query_embedding, distance: "cosine")
  end

  def generate_answer_with_context(closest_result)
    prompt = <<~PROMPT
      You are an intelligent assistant helping users answer questions based on the provided content.

      Context:
      #{closest_result.content}

      Question:
      #{@query}

      Instructions:
      - Use the information in the provided context to answer the question as accurately as possible.
      - If the context does not contain relevant information, rely on your general knowledge to provide a helpful and accurate response.
      - If neither the context nor your knowledge allows you to answer the question meaningfully, respond with: "I didn’t find any valid context or additional knowledge to answer this question."

      Answer in a clear, concise, and user-friendly manner.
    PROMPT

    answer = @service.generate_answer(prompt)
    {
      title: closest_result.title,
      url: closest_result.url,
      answer: answer,
      context: closest_result.content
    }
  end

  def generate_general_knowledge_response
    prompt = <<~PROMPT
      You are an intelligent assistant answering general questions with your vast knowledge base.

      Question:
      #{@query}

      Instructions:
      - Provide an accurate and helpful answer based on your general knowledge.
      - Be concise, clear, and user-friendly in your response.
    PROMPT

    answer = @service.generate_answer(prompt)
    {
      title: "General Knowledge",
      url: nil,
      answer: answer,
      context: "No specific context was found; the answer is based on GPT's general knowledge."
    }
  end

  def valid_context_answer?(response)
    response[:answer].strip != "I didn’t find any valid context or additional knowledge to answer this question."
  end
end
