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
    content_tag(:h2, text, class: "text-2xl font-bold")
  end

  defp present_results(results) when is_binary(results) do
    results
  end

  defp present_results(results) when is_list(results) do
    items =
      results
      |> Enum.map(fn result -> content_tag(:li, result) end)

    content_tag(:ul, items)
  end

  defmodule Section do
    def card(children) do
      content_tag(
        :article,
        children,
        class: "text-xl p-4 bg-gray-100 rounded spacing-y-4"
      )
    end
  end

  defp bundlephobia(query) do
    case Spec.search_for(:bundlephobia, query) do
      # %{"assets" => [%{"gzip" => 3920, "name" => "main", "size" => 10047, "type" => "js"}], "dependencyCount" => 0, "dependencySizes" => [%{"approximateSize" => 9537, "name" => "preact"}], "description" => "Fast 3kb React-compatible Virtual DOM library.", "gzip" => 3920, "hasJSModule" => "dist/preact.module.js", "hasJSNext" => false, "hasSideEffects" => true, "name" => "preact", "repository" => "https://github.com/preactjs/preact.git", "scoped" => false, "size" => 10047, "version" => "10.4.1"}
      %{"name" => name, "size" => size, "gzip" => size_gzip, "version" => version} ->
        emerging_3g_ms = floor(size_gzip / 50)

        Section.card([
          content_tag(:h3, "#{name}@#{version}", class: "text-2xl"),
          content_tag(
            :dl,
            [
              content_tag(:dt, "Minified", class: "font-bold"),
              content_tag(:dd, "#{size}"),
              content_tag(:dt, "Minified + Gzipped", class: "font-bold"),
              content_tag(:dd, "#{size_gzip}"),
              content_tag(:dt, "Emerging 3G (50kB/s)", class: "font-bold"),
              content_tag(:dd, "#{emerging_3g_ms}ms")
            ],
            class: "grid grid-flow-col grid-rows-2"
          )
        ])

      %{"error" => %{"code" => "PackageNotFoundError"}} ->
        content_tag(:p, "Not found")

      other ->
        inspect(other)
    end
  end

  defmodule CanIUse do
    alias ComponentsGuideWeb.ResearchController.Section

    def present(results) when is_list(results) do
      Enum.map(results, &item/1)
    end

    defp item(
           item = %{
             "title" => title,
             "description" => description,
             "notes" => notes,
             "categories" => _categories,
             "stats" => stats,
             "status" => _status
           }
         ) do
      Section.card([
        content_tag(:h3, title, class: "text-2xl"),
        content_tag(
          :dl,
          [
            content_tag(:dt, "Description", class: "font-bold"),
            content_tag(:dd, "#{description}"),
            content_tag(:dt, "Notes", class: "font-bold"),
            content_tag(:dd, "#{notes}"),
            content_tag(:dt, "Internet Explorer", class: "font-bold"),
            content_tag(:dd, "#{inspect(stats["ie"])}")
            # content_tag(:dd, "#{inspect(item)}")
          ],
          class: "grid grid-flow-col gap-4",
          style: "grid-template-rows: repeat(2, auto);"
        )
      ])
    end
  end

  defp caniuse(query) do
    case Spec.search_for(:caniuse, query) do
      results ->
        CanIUse.present(results)
    end
  end

  defp aria_practices(query) do
    case Spec.search_for(:wai_aria_practices, query) do
      results ->
        Enum.map(results, fn %{heading: heading} ->
          Section.card([
            content_tag(:h3, heading)
          ])
        end)
    end
  end

  defp load_results(query) when is_binary(query) do
    # ComponentsGuide.Research.Source.clear_cache()
    [
      content_tag(:article, [
        h2("Bundlephobia"),
        bundlephobia(query)
      ]),
      content_tag(:article, [
        h2("Can I Use"),
        caniuse(query)
      ]),
      content_tag(:article, [
        h2("HTML spec"),
        Spec.search_for(:whatwg_html_spec, query) |> present_results()
      ]),
      content_tag(:article, [
        h2("ARIA Practices"),
        aria_practices(query)
      ]),
      content_tag(:article, [
        h2("HTML ARIA"),
        Spec.search_for(:html_aria_spec, query) |> present_results()
      ])
    ]
  end
end
