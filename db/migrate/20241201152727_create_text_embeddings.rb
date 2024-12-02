class CreateTextEmbeddings < ActiveRecord::Migration[7.1]
  def change
    create_table :text_embeddings do |t|
      t.text :content
      t.timestamps
    end
    add_column :text_embeddings, :embedding, :vector, limit: 1536
  end
end
