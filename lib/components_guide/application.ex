defmodule ComponentsGuide.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    upstash_config = Application.fetch_env!(:components_guide, :upstash)
    redis_url_string = Access.fetch!(upstash_config, :redis_url)
    redis_uri = URI.new!(redis_url_string)
    IO.inspect(redis_uri)

    children = [
      # Start the Telemetry supervisor
      ComponentsGuideWeb.Telemetry,
      # Start the PubSub system
      {Phoenix.PubSub, name: ComponentsGuide.PubSub},
      # Start the Endpoint (http/https)
      ComponentsGuideWeb.Endpoint,
      # Start a worker by calling: MiniModules.Worker.start_link(arg)
      # {MiniModules.Worker, arg}

      # {Cachex, [:content_cache, []]}
      # Supervisor.child_spec({Cachex, {:content_cache, []}}, id: :content_cache)
      %{
        id: :content_cache,
        start: {Cachex, :start_link, [:content_cache, []]}
      },
      %{
        id: :research_spec_cache,
        start: {Cachex, :start_link, [:research_spec_cache, []]}
      },
      # {Redix, {Access.fetch!(upstash_config, :redis_url), [name: :upstash_redix]}}
      # {Redix, {redis_url_string, [name: :upstash_redix]}}
      # ComponentsGuide.Worker
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: ComponentsGuide.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    ComponentsGuideWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
