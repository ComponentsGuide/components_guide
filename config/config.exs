# This file is responsible for configuring your application
# and its dependencies with the aid of the Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
import Config

# Configures the endpoint
config :components_guide, ComponentsGuideWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "GIQzLogQXRdH7r9im+a6kEsZIbX6FmAvCt8bj+BYSkBahfkl6u9oRHSPs7Go81at",
  render_errors: [view: ComponentsGuideWeb.ErrorView, accepts: ~w(html json)],
  pubsub_server: ComponentsGuide.PubSub,
  live_view: [signing_salt: "JNYbgmOL"]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

config :floki, :html_parser, Floki.HTMLParser.Html5ever

# Allow rendering markdown templates
config :phoenix, :template_engines,
  md: ComponentsGuideWeb.TemplateEngines.MarkdownEngine,
  png: ComponentsGuideWeb.TemplateEngines.ImageEngine,
  collected: ComponentsGuideWeb.TemplateEngines.ImageEngine

# Configure esbuild (the version is required)
config :esbuild,
  version: "0.14.0",
  default: [
    args:
      ~w(js/app.js --bundle --target=es2017 --outdir=../priv/static/assets --external:/fonts/* --external:/images/*),
    cd: Path.expand("../assets", __DIR__),
    env: %{
      "NODE_PATH" =>
        [
          Path.expand("../deps", __DIR__),
          Path.expand("../assets", __DIR__)
        ]
        |> Enum.join(":")
    }
  ]

config :tailwind,
  version: "3.0.10",
  default: [
    args: ~w(
    --config=tailwind.config.js
    --input=css/app.css
    --output=../priv/static/assets/app.css
  ),
    cd: Path.expand("../assets", __DIR__)
  ]

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs"
