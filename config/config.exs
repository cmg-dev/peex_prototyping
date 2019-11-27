import Config

config :peex_protyping, Peex.Processtoken.Repo,
  database: "peex_prototyping",
  username: "user",
  password: "pass",
  hostname: "localhost"

config :peex_protyping, ecto_repos: [Peex.Processtoken.Repo]
