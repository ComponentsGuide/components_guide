defmodule ComponentsGuideWeb.ReactTypescriptController do
  use ComponentsGuideWeb, :controller_view

  def index(conn, _params) do
    conn
    |> assign(:page_title, "React and TypeScript")
    |> render("index.html", article: "tips")
  end

  @articles %{
    "lifecycle" => %{title: "React Lifecycle"},
    "testing" => %{title: "Testing React"},
    "forms" => %{title: "Creating Forms in React"},
    "state-levels" => %{title: "Levels of State in React"},
    "reducer-patterns" => %{title: "React Reducer Patterns"},
    "goodbye-use-effect" => %{title: "Goodbye useEffect"},
    "form-reducers" => %{title: "Reduce form boilerplate with React reducers"},
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

defmodule ComponentsGuideWeb.ReactTypescriptView do
  use ComponentsGuideWeb, :view

  @prose_class "prose md:prose-xl prose-invert max-w-4xl mx-auto py-16"

  def article_content_class("editor"), do: "content text-xl"
  def article_content_class("editor-prolog"), do: "content text-xl"
  def article_content_class(_article), do: @prose_class

  def table_rows(rows_content) do
    Enum.map(rows_content, &table_row/1)
  end

  def table_row(items) do
    content_tag(:tr, Enum.map(items, &table_cell/1))
  end

  def table_cell(content) do
    content_tag(:td, content |> line(), class: "px-3 py-1")
  end
end
