defmodule ComponentsGuideWeb.ResearchController do
  use ComponentsGuideWeb, :controller
  use Phoenix.HTML

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

  defp h2(text) do
    content_tag(:h2, text, class: "font-bold")
  end

  defp present_results(results) when is_binary(results) do
    results
  end

  defp present_results(results) when is_list(results) do
    items = results
    |> Enum.map(fn result -> content_tag(:li, result) end)

    content_tag(:ul, items)
  end

  defp load_results(query) when is_binary(query) do
    # ComponentsGuide.Research.Source.clear_cache()
    [
      content_tag(:article, [
        h2("Bundlephobia"),
        Spec.search_for(:bundlephobia, query) |> present_results()
      ]),
      content_tag(:article, [
        h2("Can I Use"),
        Spec.search_for(:caniuse, query) |> present_results()
      ]),
      content_tag(:article, [
        h2("HTML spec"),
        Spec.search_for(:whatwg_html_spec, query) |> present_results()
      ]),
      content_tag(:article, [
        h2("HTML ARIA"),
        Spec.search_for(:html_aria_spec, query) |> present_results()
      ])
    ]
  end
end
