defmodule ComponentsGuideWeb.ReactTypescriptController do
  use ComponentsGuideWeb, :controller

  def index(conn, _params) do
    render(conn, "index.html", article: "tips")
  end

  @articles ["testing"]

  def show(conn, %{"article" => article}) when article in @articles do
    render(conn, "index.html", article: article)
  end
end
