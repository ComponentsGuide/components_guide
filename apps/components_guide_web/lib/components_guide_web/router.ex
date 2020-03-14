defmodule ComponentsGuideWeb.Router do
  use ComponentsGuideWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug Phoenix.LiveView.Flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", ComponentsGuideWeb do
    pipe_through :browser

    get "/", LandingController, :index

    get "/links", LinksController, :index

    get "/accessibility-first-testing", AccessibilityFirstTestingController, :index
    get "/swiftui", SwiftUIController, :index
    get "/react+typescript", ReactTypescriptController, :index

    resources "/text", TextController
    get "/text/:id/text/:format", TextController, :show_text_format

    get "/fake-search", FakeSearchController, :index
  end

  # Other scopes may use custom stacks.
  # scope "/api", ComponentsGuideWeb do
  #   pipe_through :api
  # end
end
