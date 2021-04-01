defmodule ComponentsGuideWeb.AccessibilityFirstController do
  use ComponentsGuideWeb, :controller
  require Logger

  def index(conn, _params) do
    conn
    |> assign(:page_title, page_title(nil))
    |> render("index.html", article: "intro")
  end

  def show(conn, %{"id" => "widgets-cheatsheet"}) do
    conn
    |> assign(:page_title, "Accessible Widgets Cheatsheet")
    |> render("widgets-cheatsheet.html")
  end

  def show(conn, %{"id" => "properties-cheatsheet"}) do
    conn
    |> assign(:page_title, "Accessible Properties Cheatsheet")
    |> render("properties-cheatsheet.html")
  end

  @articles ["navigation", "landmarks", "roles", "accessible-name", "forms", "content"]

  def show(conn, %{"id" => article}) when article in @articles do
    conn
    |> assign(:page_title, page_title(article))
    |> render("index.html", article: article)
  end

  def show(conn, _params) do
    raise Phoenix.Router.NoRouteError, conn: conn, router: ComponentsGuideWeb.Router
  end

  defp page_title("navigation"), do: "Accessibility-First Navigation"
  defp page_title("landmarks"), do: "Accessibility-First Landmarks"
  defp page_title("roles"), do: "Accessibility-First Roles"
  defp page_title("forms"), do: "Accessibility-First Forms"
  defp page_title("content"), do: "Accessibility-First Content"
  defp page_title("accessible-name"), do: "Learning Accessible Names"

  defp page_title(_) do
    "Accessibility-First Development"
  end
end
