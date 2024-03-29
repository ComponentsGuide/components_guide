defmodule ComponentsGuideWeb.WebStandardsController do
  use ComponentsGuideWeb, :controller_view
  require Logger

  def index(conn, _params) do
    render(conn, "index.html", article: "intro")
  end

  @articles [
    "url",
    "http-caching",
    "html",
    "http-headers",
    "media-queries",
    "promise",
    "robots-txt",
  ]

  def show(conn, %{"id" => article}) when article in @articles do
    render(conn, "index.html", article: article)
  end

  def show(conn, _params) do
    raise Phoenix.Router.NoRouteError, conn: conn, router: ComponentsGuideWeb.Router
  end
end

defmodule ComponentsGuideWeb.WebStandardsView do
  use ComponentsGuideWeb, :view
  use ComponentsGuideWeb.Snippets
  alias ComponentsGuideWeb.ThemeView

  def header_styles() do
    ThemeView.banner_styles(:web_standards)
  end
end
