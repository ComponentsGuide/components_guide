# This file is responsible for configuring your umbrella
# and **all applications** and their dependencies with the
# help of Mix.Config.
#
# Note that all applications in your umbrella share the
# same configuration and dependencies, which is why they
# all use the same configuration file. If you want different
# configurations or dependencies per app, it is best to
# move said applications out of the umbrella.
use Mix.Config

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

# Allow rendering markdown templates
config :phoenix, :template_engines,
  md: ComponentsGuideWeb.TemplateEngines.MarkdownEngine,
  png: ComponentsGuideWeb.TemplateEngines.ImageEngine,
  collected: ComponentsGuideWeb.TemplateEngines.ImageEngine

config :tailwind, version: "3.0.18", default: [
  args: ~w(
    --config=tailwind.config.js
    --input=css/app.css
    --output=../priv/static/assets/app.css
  ),
  cd: Path.expand("../assets", __DIR__)
]

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
