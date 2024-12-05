class TextEmbedding < ApplicationRecord
  has_neighbors :embedding

  validates :content, :embedding, presence: true
  validates :course_name, :course_description, :course_category, presence: true
end
