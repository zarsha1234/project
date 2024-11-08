# This file is responsible for configuring your application
# and its dependencies with the aid of the Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.
import Config

# General application configuration
config :todo,
  ecto_repos: [Todo.Repo],
  generators: [timestamp_type: :utc_datetime]

# Configures the endpoint
config :todo, TodoWeb.Endpoint,
  url: [host: "localhost"],
  adapter: Bandit.PhoenixAdapter,
  render_errors: [
    formats: [html: TodoWeb.ErrorHTML, json: TodoWeb.ErrorJSON],
    layout: false
  ],
  pubsub_server: Todo.PubSub, # Correct key for PubSub server
  live_view: [signing_salt: "oVmb+ool"]

# Configures the mailer
config :todo, Todo.Mailer, adapter: Swoosh.Adapters.Local

# Configure esbuild
config :esbuild,
  version: "0.17.11",
  todo: [
    args:
      ~w(js/app.js --bundle --target=es2017 --outdir=../priv/static/assets --external:/fonts/* --external:/images/*),
    cd: Path.expand("../assets", __DIR__),
    env: %{"NODE_PATH" => Path.expand("../deps", __DIR__)}
  ]

# Configure tailwind
config :tailwind,
  version: "3.4.3",
  todo: [
    args: ~w(
      --config=tailwind.config.js
      --input=css/app.css
      --output=../priv/static/assets/app.css
    ),
    cd: Path.expand("../assets", __DIR__)
  ]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Time zone configuration
config :elixir, :time_zone_database, Tzdata.TimeZoneDatabase

# Import environment specific config
import_config "#{config_env()}.exs"
