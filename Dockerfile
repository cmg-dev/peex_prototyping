# syntax=docker/dockerfile:1
# Development-only Dockerfile for the Peex process engine (MkI).
# Build context: this repository's root directory.
#
#   docker build -t peex-prototype:latest .
#
FROM elixir:1.16-slim

RUN mix local.hex --force && mix local.rebar --force

WORKDIR /app

# Layer-cache: deps first
COPY mix.exs mix.lock ./
COPY config/ config/
RUN mix deps.get && mix deps.compile

# Application source + migrations + BPMN processes
COPY lib/ lib/
COPY priv/ priv/
COPY processes/ processes/
RUN mix compile

# Inject runtime.exs so the DB hostname can be set via environment variables.
# App name is :peex_protyping (typo is intentional — matches upstream mix.exs).
RUN cat > /app/config/runtime.exs <<'RUNTIME'
import Config

config :peex_protyping, Peex.Processtoken.Repo,
  database: System.get_env("DATABASE_NAME") || "peex_prototyping",
  username: System.get_env("DATABASE_USER") || "postgres",
  password: System.get_env("DATABASE_PASS") || "postgres",
  hostname: System.get_env("DATABASE_HOST") || "localhost"
RUNTIME

# Wait-for-tcp helper using Erlang (already installed in image)
RUN cat > /app/wait-for-tcp.sh <<'WAITSCRIPT'
#!/bin/sh
HOST=$1
PORT=$2
echo "Waiting for $HOST:$PORT ..."
until erl -noshell -eval "case gen_tcp:connect(\"$HOST\", $PORT, [], 5000) of {ok,S} -> gen_tcp:close(S), halt(0); _ -> halt(1) end." 2>/dev/null; do
  sleep 2
done
echo "$HOST:$PORT is reachable."
WAITSCRIPT
RUN chmod +x /app/wait-for-tcp.sh

# Entrypoint: wait for Postgres, run migrations, start engine
RUN cat > /app/entrypoint.sh <<'ENTRYPOINT'
#!/bin/sh
set -e
/app/wait-for-tcp.sh ${DATABASE_HOST:-localhost} 5432
echo "Creating database (if needed)..."
mix ecto.create 2>/dev/null || true
echo "Running migrations..."
mix ecto.migrate 2>/dev/null || true
echo "Starting Peex engine..."
exec mix run --no-halt
ENTRYPOINT
RUN chmod +x /app/entrypoint.sh

ENTRYPOINT ["/app/entrypoint.sh"]
