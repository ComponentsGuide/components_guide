defmodule ComponentsGuideWeb.AccessibilityFirstController do
  use ComponentsGuideWeb, :controller
  require Logger

  def index(conn, _params) do
    render(conn, "index.html")
  end

  def show(conn, %{"id" => "landmarks"}) do
    render(conn, "landmarks.html")
  end

  def show(conn, %{"id" => "widgets-cheatsheet"}) do
    render(conn, "widgets-cheatsheet.html")
  end

  def show(conn, %{"id" => "properties-cheatsheet"}) do
    render(conn, "properties-cheatsheet.html")
  end

  @articles ["navigation", "forms"]

  def show(conn, %{"id" => article}) when article in @articles do
    render(conn, "index.html", article: article)
  end

  def show(conn, _params) do
    raise Phoenix.Router.NoRouteError, conn: conn, router: ComponentsGuideWeb.Router
  end
end
