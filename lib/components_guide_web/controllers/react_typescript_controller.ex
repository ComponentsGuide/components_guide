defmodule ComponentsGuideWeb.ReactTypescriptController do
  use ComponentsGuideWeb, :controller

  def index(conn, _params) do
    conn
    |> assign(:page_title, "React and TypeScript")
    |> render("index.html", article: "tips")
  end

  @articles %{
    "testing" => %{title: "Testing React"},
    "forms" => %{title: "Creating Forms in React"},
    "reducer-patterns" => %{title: "React Reducer Patterns"},
    "zero-hook-dependencies" => %{title: "Zero Hook Dependencies"},
    "hooks-concurrent-world" => %{title: "React Hooks in a Concurrent World"},
    "logical-clocks" => %{title: "Logical Clocks in React"},
    "editor" => %{title: "React Online Editor"},
    "editor-prolog" => %{title: "Prolog Online Editor"}
  }

  def show(conn, %{"article" => article}) when is_map_key(@articles, article) do
    conn
    |> assign(:page_title, @articles[article].title)
    |> render("index.html", article: article)
  end
end
