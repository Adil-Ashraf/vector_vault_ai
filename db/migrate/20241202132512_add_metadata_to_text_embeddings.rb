class AddMetadataToTextEmbeddings < ActiveRecord::Migration[7.1]
  def change
    add_column :text_embeddings, :title, :string
    add_column :text_embeddings, :url, :string
    add_column :text_embeddings, :full_content, :text
  end
end
