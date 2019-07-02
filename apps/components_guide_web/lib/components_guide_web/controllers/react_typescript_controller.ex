defmodule ComponentsGuideWeb.ReactTypescriptController do
  use ComponentsGuideWeb, :controller

  def index(conn, _params) do
    render(conn, "index.html")
  end
end
