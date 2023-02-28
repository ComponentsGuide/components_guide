defmodule ComponentsGuideWeb.LinksController do
  use ComponentsGuideWeb, :controller_view

  def index(conn, _params) do
    render(conn, "index.html")
  end
end
