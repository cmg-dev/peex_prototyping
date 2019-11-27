# Peex.MkI

**TODO: Add description**

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `peex_protyping` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:peex_protyping, "~> 0.1.0"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at [https://hexdocs.pm/peex_protyping](https://hexdocs.pm/peex_protyping).

## Developer Setup

### Database

1. Create the database using Docker

   `docker run --name peex-postgres -e POSTGRES_PASSWORD=pass -e POSTGRES_USER=user -p 5432:5432 -d postgres:12-alpine`

1. Connect to the database

   `psql -h localhost -p 5432 -U user --password`

1. (Optional): Run the migrations

  See [section about Migrations](#migrations)

1. Select database and query

   `\c peex_protyping`

   `SELECT * FROM processtokens;`

   This should return empty for the initial setup, as there is no table `processtokens`, yet.

   If this succeeds, quit the command line with `\q` and proceed.

### Migrations

To install all migrations, run:

`mix ecto.migrate`

### RabbitMQ

1. Create a RabbitMQ instance using Docker; we use the standard AMQP ports

   `docker run --name peex-rabbitmq -p 5672:5672 -d rabbitmq:3-alpine`

### Example Server

1. Go to example project folder

   `cd peex_example/`

1. Install dependencies

   `mix deps.get`

1. Start server

   `mix run --no-halt`

### Live Execution Tracking Client

1. Go to client folder
   
   `cd client/`

1. Install dependencies

   `npm install`

1. Start client

   `npm start`

1. Open client at http://localhost:3000
