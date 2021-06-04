defmodule ComponentsGuideWeb.CheatsheetsController do
  use ComponentsGuideWeb, :controller
  require Logger

  def index(conn, _params) do
    render(conn, "index.html", article: "intro")
  end

  @articles ["rxjs"]

  def show(conn, %{"id" => article}) when article in @articles do
    render(conn, "index.html", article: article)
  end

  def show(conn, _params) do
    raise Phoenix.Router.NoRouteError, conn: conn, router: ComponentsGuideWeb.Router
  end
end

defmodule ComponentsGuideWeb.CheatsheetsView do
  use ComponentsGuideWeb, :view
  use ComponentsGuideWeb.Snippets
  alias ComponentsGuideWeb.ThemeView

  def header_styles() do
    ThemeView.banner_styles(:cheatsheets)
  end
end