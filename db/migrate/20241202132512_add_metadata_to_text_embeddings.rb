class AddMetadataToTextEmbeddings < ActiveRecord::Migration[7.1]
  def change
    add_column :text_embeddings, :course_name, :string
    add_column :text_embeddings, :course_description, :text
    add_column :text_embeddings, :course_category, :string
  end
end
