import Config

config :peex_persistence, Peex.Persistence.Repo,
  database: "peex_prototyping",
  username: "user",
  password: "pass",
  hostname: "localhost"

config :peex_persistence, ecto_repos: [Peex.Persistence.Repo]
