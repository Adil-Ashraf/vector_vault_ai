class TextEmbedding < ApplicationRecord
  has_neighbors :embedding

  validates :content, :embedding, presence: true
  validates :title, presence: true
  # validates :url, presence: true, format: { with: URI::DEFAULT_PARSER.make_regexp, message: "must be a valid URL" }
end
