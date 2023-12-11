defmodule ComponentsGuideWeb.Router do
  use ComponentsGuideWeb, :router

  pipeline :browser do
    plug(:accepts, ["html"])
    plug(:fetch_session)
    plug(:fetch_live_flash)
    plug(:put_root_layout, {ComponentsGuideWeb.LayoutView, :root})
    plug(:protect_from_forgery)
    plug(:put_secure_browser_headers)
  end

  pipeline :api do
    plug(:accepts, ["json"])
  end

  pipeline :wasm_output do
    plug(:accepts, ["html", "xml"])
    plug(:fetch_session)
    plug(:fetch_live_flash)
    plug(:put_root_layout, {ComponentsGuideWeb.LayoutView, :root})
    # plug(:protect_from_forgery)
    plug(:put_secure_browser_headers)
  end

  pipeline :dynamic_scripts do
    plug(:put_secure_browser_headers)
  end

  scope "/wasm/script", ComponentsGuideWeb do
    get("/:script", WasmController, :script)
  end

  # scope "/wasm/to-html", ComponentsGuideWeb do
  #   get("/:module", WasmController, :to_html)
  # end

  scope "/wasm-demo/:module", ComponentsGuideWeb do
    pipe_through(:wasm_output)

    get("/", WasmController, :root)

    get("/:function", WasmController, :output_function)
    # get("/:xml.xml", WasmController, :to_xml)
  end

  scope "/", ComponentsGuideWeb do
    pipe_through(:browser)

    get("/~/content-length", ContentLengthController, :index)

    get("/", LandingController, :index)

    resources "/react-playground", ReactEditorController, only: [:index, :show]

    get("/research", ResearchController, :index)
    get("/research/:section", ResearchController, :show)

    get("/concepts", ConceptsController, :index)

    get("/links", LinksController, :index)

    resources(
      "/accessibility-first",
      AccessibilityFirstController,
      only: [:index, :show]
    )

    resources(
      "/composable-systems",
      ComposableSystemsController,
      only: [:index, :show]
    )

    resources(
      "/web-standards",
      WebStandardsController,
      only: [:index, :show]
    )

    resources(
      "/robust-javascript",
      RobustJavascriptInteractivityController,
      only: [:index, :show]
    )

    resources(
      "/graphics",
      GraphicsController,
      only: [:index, :show]
    )

    resources(
      "/cheatsheets",
      CheatsheetsController,
      only: [:index, :show]
    )

    get("/calendar", CalendarController, :index)

    get("/wasm", WasmController, :index)
    get("/wasm/module/:module", WasmController, :module)
    live("/wasm/http-server", WasmHTTPServerLive)

    live("/view-source", ViewSourceLive)
    live("/view-github-repo", ViewGithubRepoLive)

    live("/latency-comparison", LatencyComparisonLive)
    live("/latency-comparison/:section", LatencyComparisonLive)
    live("/latency-calculator", LatencyCalculatorLive)

    live("/browser-compat", BrowserCompatLive)

    live("/wasm-inspector", WasmInspectorLive)

    live("/color", ColorLive, :index)
    live("/color/:definition", ColorLive, :show)
    live("/color/lab/:definition", ColorLive, :lab)

    get("/swiftui", SwiftUIController, :index)

    get("/react+typescript", ReactTypescriptController, :index)
    get("/react+typescript/:article", ReactTypescriptController, :show)

    resources("/text", TextController)
    get("/text/:id/text/:format", TextController, :show_text_format)

    get("/fake-search", FakeSearchController, :index)
  end

  # Other scopes may use custom stacks.
  scope "/api", ComponentsGuideWeb do
    pipe_through :api

    get("/wasm", WasmController, :index)
  end

  # Enables LiveDashboard only for development
  #
  # If you want to use the LiveDashboard in production, you should put
  # it behind authentication and allow only admins to access it.
  # If your application does not have an admins-only section yet,
  # you can use Plug.BasicAuth to set up some basic authentication
  # as long as you are also using SSL (which you should anyway).
  if Mix.env() in [:dev, :test] do
    import Phoenix.LiveDashboard.Router

    scope "/" do
      pipe_through(:browser)
      live_dashboard("/dashboard", metrics: ComponentsGuideWeb.Telemetry)
    end
  end
end
