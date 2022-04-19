defmodule ComponentsGuide.MixProject do
  use Mix.Project

  def project do
    [
      app: :components_guide,
      version: "0.1.0",
      elixir: "~> 1.12",
      elixirc_paths: elixirc_paths(Mix.env()),
      compilers: [:phoenix, :gettext] ++ Mix.compilers(),
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps()
    ]
  end

  # Configuration for the OTP application.
  #
  # Type `mix help compile.app` for more information.
  def application do
    [
      mod: {ComponentsGuide.Application, []},
      extra_applications: [:logger, :runtime_tools]
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Specifies your project dependencies.
  #
  # Type `mix help deps` for examples and options.
  defp deps do
    [
      {:phoenix, "~> 1.6.6"},
      {:phoenix_pubsub, "~> 2.0"},
      {:phoenix_html, "~> 3.1"},
      {:phoenix_ecto, "~> 4.0"},
      {:phoenix_live_view, "~> 0.17"},
      {:phoenix_live_reload, "~> 1.2", only: :dev},
      {:phoenix_live_dashboard, "~> 0.6"},
      {:esbuild, "~> 0.3", runtime: Mix.env() == :dev},
      {:tailwind, "~> 0.1", runtime: Mix.env() == :dev},
      {:telemetry_metrics, "~> 0.4"},
      {:telemetry_poller, "~> 0.4"},
      {:gettext, "~> 0.11"},
      {:unicode_guards, "~> 1.0"},
      {:cachex, "~> 3.1"},
      {:ecto, "~> 3.6.2"},
      {:httpotion, "~> 3.1.0"},
      {:jason, "~> 1.0"},
      {:tesla, "~> 1.3.0"},
      {:mojito, "~> 0.6.1"},
      {:mint, "~> 1.0"},
      {:floki, "~> 0.26.0"},
      {:plug_cowboy, "~> 2.0"},
      {:earmark, "~> 1.4.15"},
      {:paredown, "~> 0.1.0"},
      {:ex_image_info, "~> 0.2.4"},
      {:rustler, "~> 0.25.0"},
      {:benchee, "~> 1.0", only: :dev},
      {:reverse_proxy_plug, "~> 1.3.1", only: :dev}
    ]
  end

  # Aliases are shortcuts or tasks specific to the current project.
  #
  # See the documentation for `Mix` for more info on aliases.
  defp aliases do
    [
      setup: ["cmd mkdir -p tmp", "deps.get", "cmd npm --prefix assets ci"],
      "assets.deploy": [
        "template_assets",
        "tailwind.install",
        "tailwind default --minify",
        "esbuild default --minify",
        "phx.digest"
      ],
      production_build: [
        "cmd rustup install stable",
        "cmd rustup default stable",
        "setup",
        "assets.deploy",
        "compile"
      ]
    ]
  end
end
