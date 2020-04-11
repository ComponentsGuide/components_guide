defmodule ComponentsGuideWeb.ResearchController do
  use ComponentsGuideWeb, :controller

  alias ComponentsGuide.HTTPClient

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
    url = "https://html.spec.whatwg.org/"
    result = HTTPClient.get(url)
    {:ok, response} = result
    html = response.body
    html
  end
end
