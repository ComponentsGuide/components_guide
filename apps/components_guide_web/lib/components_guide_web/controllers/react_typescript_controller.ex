defmodule ComponentsGuideWeb.ReactTypescriptController do
  use ComponentsGuideWeb, :controller

  def index(conn, _params) do
    conn
    |> assign(:page_title, "React and TypeScript")
    |> render("index.html", article: "tips")
  end

  @articles ["testing", "forms", "event-handlers", "logical-clocks", "editor", "editor-prolog"]

  def show(conn, %{"article" => article}) when article in @articles do
    render(conn, "index.html", article: article)
  end
end
