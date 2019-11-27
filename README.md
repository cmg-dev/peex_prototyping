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
