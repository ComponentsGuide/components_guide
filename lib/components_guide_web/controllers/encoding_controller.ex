defmodule ComponentsGuideWeb.EncodingController do
  use ComponentsGuideWeb, :controller_view
  require Logger

  def index(conn, _params) do
    render(conn, "index.html", article: "intro")
  end

  @articles ["base64", "utf8"]

  def show(conn, %{"id" => article}) when article in @articles do
    render(conn, "index.html", article: article)
  end

  def show(conn, _), do: raise Phoenix.Router.NoRouteError, conn: conn, router: ComponentsGuideWeb.Router
end

defmodule ComponentsGuideWeb.EncodingView do
  use ComponentsGuideWeb, :view
  use ComponentsGuideWeb.Snippets
  alias ComponentsGuideWeb.ThemeView

  def header_styles() do
    ThemeView.banner_styles(:encoding)
  end
end
