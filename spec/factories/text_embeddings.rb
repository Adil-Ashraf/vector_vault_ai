FactoryBot.define do
  factory :text_embedding do
    title { "Sample Document" }
    url { "https://example.com/doc" }
    content { "Some chunk of course content used for context." }
    embedding { Array.new(1536) { rand(-1.0..1.0) } }
  end
end
