defmodule ComponentsGuideWeb.AccessibilityFirstTestingController do
  use ComponentsGuideWeb, :controller

  def index(conn, _params) do
    render(conn, "index.html")
  end

  def show(conn, _params) do
    render(conn, "roles-cheatsheet.html")
  end
end
