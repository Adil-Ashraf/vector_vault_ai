# Vector Vault AI

A Rails API for retrieval-augmented question answering: content is chunked, embedded with
OpenAI, and stored in Postgres via `pgvector`; queries embed the question, find the nearest
stored chunk, and ask an LLM to answer grounded in that context (falling back to general
knowledge when no good match is found).

## Stack

- Ruby 3.3.1 / Rails 7.1 (API-only)
- Postgres + [pgvector](https://github.com/pgvector/pgvector) via the `neighbor` gem
- OpenAI (`text-embedding-3-small` for embeddings, `gpt-4o-mini` for answers)
- RSpec, FactoryBot, WebMock for testing

## Running locally with Docker (recommended)

```bash
cp .env.example .env   # fill in OPENAI_API_KEY and API_KEY
docker compose up --build
```

This starts a `pgvector/pgvector` Postgres instance and the Rails app on
`http://localhost:3000`, creating/migrating the database on boot.

Run the test suite inside the container:

```bash
docker compose run --rm web bundle exec rspec
```

## Running locally without Docker

Requires Ruby 3.3.1 and a local Postgres with the `vector` extension available.

```bash
cp .env.example .env   # fill in OPENAI_API_KEY, API_KEY, DATABASE_*
bundle install
bin/rails db:prepare
bin/rails server
```

For tests, copy `.env.example` to `.env.test` as well, then run `bundle exec rspec`.

## Authentication

Every API endpoint requires an `X-API-Key` header matching the `API_KEY` environment
variable:

```bash
curl -X POST http://localhost:3000/api/v1/text_embeddings \
  -H "X-API-Key: $API_KEY" \
  -d "title=Example" -d "url=https://example.com" -d "content=Some content to embed."

curl -X POST http://localhost:3000/api/v1/query/ask \
  -H "X-API-Key: $API_KEY" \
  -d "query=What is this document about?"
```

## CI/CD

`.github/workflows/ci-cd.yml` runs on every push/PR:

- **CI**: spins up a `pgvector/pgvector` Postgres service, runs `bundler-audit`, and runs
  the RSpec suite.
- **CD**: on push to `main`, once CI passes, builds the production `Dockerfile` image and
  pushes it to `ghcr.io/<repo>` tagged `latest` and by commit SHA.
