defmodule ComponentsGuideWeb.WebController do
  use ComponentsGuideWeb, :controller
  require Logger

  def index(conn, _params) do
    render(conn, "index.html", article: "intro")
  end

  @articles ["url", "promise"]

  def show(conn, %{"id" => article}) when article in @articles do
    render(conn, "index.html", article: article)
  end

  def show(conn, _params) do
    raise Phoenix.Router.NoRouteError, conn: conn, router: ComponentsGuideWeb.Router
  end
end

defmodule ComponentsGuideWeb.WebView do
  use ComponentsGuideWeb, :view

  use ComponentsGuideWeb.Snippets

  def header_styles() do
    color = {:lab, 47, 10, -44}

    gradient = Styling.linear_gradient("150grad", [
      {:lab, 47, 5, -44},
      {:lab, 47, -24, -44},
      color,
      {:lab, 47, 53, -44}
    ])

    "background-color: #{color |> Styling.to_css()}; background-image: #{gradient};"
  end
end
