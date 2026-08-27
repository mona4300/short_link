# Short Link

Rails 8 API that encodes a public URL into a short code and decodes that code back to the original URL.

- `POST /encode` with JSON `{ "url": "https://example.com" }`
- `GET /decode/:code`

The app runs behind Phusion Passenger on port 80 when using Docker Compose.

## Prerequisites

- [Docker](https://docs.docker.com/get-docker/) and [Docker Compose](https://docs.docker.com/compose/)

## Local setup with Docker

1. Copy the sample environment file and edit values if needed:

   ```bash
   cp env.example .env
   ```

   Set `USER_ID` to your host UID so bind-mounted files keep the right owner:

   ```bash
   id -u
   ```

2. Build and start Postgres and the web app:

   ```bash
   docker compose up --build
   ```

   Add `-d` to run in the background.

3. Create and migrate the database (first run, or after pulling new migrations):

   ```bash
   docker compose exec -u app web bundle exec rails db:prepare
   ```

4. Confirm the app is up:

   ```bash
   curl http://localhost/up
   ```

The API is available at `http://localhost` (host port 80).

## Environment variables

Copy `env.example` to `.env`. Docker Compose reads `.env` automatically.

### Required for Docker Compose (`env.example`)

| Variable | Purpose | Example |
| --- | --- | --- |
| `PASSENGER_RUBY_VERSION` | Tag for the `phusion/passenger-ruby34` image | `3.2.0` |
| `USER_ID` | UID/GID of the `app` user in the web container | `1000` (`id -u`) |
| `ENV_ARG` | Build-time environment; use `development` locally | `development` |
| `POSTGRES_USER` | Postgres user (also Rails `DATABASE_USERNAME`) | `postgres` |
| `POSTGRES_PASSWORD` | Postgres password (also Rails `DATABASE_PASSWORD`) | `postgres` |
| `POSTGRES_DB` | Development database name (also Rails `DATABASE_NAME`) | `webapp_development` |

### Set by Compose for the web service

These are injected into the `web` container; you normally do not set them in `.env`.

| Variable | Default in Compose |
| --- | --- |
| `RAILS_ENV` | `development` |
| `DATABASE_HOST` | `db` |
| `DATABASE_PORT` | `5432` |
| `DATABASE_USERNAME` | `$POSTGRES_USER` |
| `DATABASE_PASSWORD` | `$POSTGRES_PASSWORD` |
| `DATABASE_NAME` | `$POSTGRES_DB` |

The test database is always `webapp_test`.

## Commands

Run app commands **inside** the web container. The service name is `web`.

### App and database

```bash
docker compose exec -u app web bundle exec rails db:prepare
docker compose exec -u app web bundle exec rails db:migrate
docker compose exec -u app web bundle exec rails db:seed
docker compose exec -u app web bundle exec rails console
docker compose exec -u app web bundle exec rails runner 'puts ShortLink.count'
```

### Tests and lint

```bash
docker compose exec -u app web bundle exec rspec
docker compose exec -u app web bin/rubocop
docker compose exec -u app web bin/brakeman --no-pager
```

### Gems

```bash
docker compose exec -u app web bundle install
```

### Compose lifecycle

```bash
docker compose up --build
docker compose up -d
docker compose logs -f web
docker compose down
```

`docker compose down` stops containers. Add `-v` only if you also want to wipe the Postgres data volume.

## API smoke test

```bash
curl -s -X POST http://localhost/encode \
  -H 'Content-Type: application/json' \
  -d '{"url":"https://www.google.com"}'
```

```bash
curl -s http://localhost/decode/CODE
```
