defmodule ComponentsGuideWeb.ResearchController do
  use ComponentsGuideWeb, :controller

  alias ComponentsGuide.Research.Spec

  def index(conn, %{"q" => query}) do
    query = query |> String.trim()

    case query do
      "" ->
        render(conn, "empty.html")

      query ->
        results = load_results(query)
        render(conn, "index.html", %{query: query, results: results})
    end
  end

  def index(conn, _params) do
    index(conn, %{"q" => ""})
  end

  defp load_results(query) when is_binary(query) do
    # Spec.clear_search_cache()
    Spec.search_for(:whatwg_html_spec, query)
  end
end
