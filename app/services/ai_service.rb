require 'openai'

class AiService
  def initialize(api_key = ENV['OPENAI_API_KEY'])
    @client = OpenAI::Client.new(access_token: api_key)
  end

  def split_text_into_chunks(text, chunk_size = 2500, overlap_size = 500)
    # Configure Baran RecursiveCharacterTextSplitter
    splitter = Baran::RecursiveCharacterTextSplitter.new(
      chunk_size: chunk_size,
      chunk_overlap: overlap_size,
      separators: ["\n\n", "\n", "."]
    )

    # Split the text and return only the text chunks
    splitter.chunks(text).map { |chunk| chunk[:text] }
  end

  def generate_embedding(text)
    response = @client.embeddings(
      parameters: {
        model: 'text-embedding-ada-002',
        input: text
      }
    )
    response['data'][0]['embedding']
  end

  def generate_answer(prompt)
    response = @client.chat(
      parameters: {
        model: 'gpt-4o-mini',
        messages: [
          { 
            role: 'system', 
            content: <<~SYSTEM
              You are an intelligent assistant designed to help users by answering questions based on the provided course content. 
              Follow these rules strictly:
              - Always prioritize the provided context when forming your answer.
              - If the context does not contain sufficient information, use your general knowledge to answer the question as accurately as possible.
              - If neither the context nor your general knowledge allows you to answer meaningfully, respond with: "I couldn’t find any valid information to answer your question."
              - Be concise and user-friendly in your responses, but provide enough detail to be helpful.
              - Avoid making up information or assuming facts not supported by the context or your knowledge base.
            SYSTEM
          },
          { role: 'user', content: prompt }
        ],
        max_tokens: 3000
      }
    )

    response['choices'][0]['message']['content']
  end
end
