defmodule ComponentsGuideWeb.ColorController do
  use ComponentsGuideWeb, :controller

  def index(conn, _params) do
    Phoenix.Component.live_render(conn, ComponentsGuideWeb.ColorLive)
    # render(conn, "index.html")
  end
end
