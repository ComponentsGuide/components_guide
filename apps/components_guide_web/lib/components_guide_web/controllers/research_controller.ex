defmodule ComponentsGuideWeb.ResearchController do
  use ComponentsGuideWeb, :controller
  use Phoenix.HTML

  alias ComponentsGuide.Research.Spec
  alias ComponentsGuide.Research.Static
  alias ComponentsGuideWeb.ResearchView, as: View

  def index(conn, %{"q" => query, "turbo" => _}) do
    query = query |> String.trim()

    case query do
      "" ->
        render(conn, "empty.html")

      query ->
        results = load_results(query)
        render(conn, "turbo-results.html", %{query: query, results: results})
    end
  end

  def index(conn, %{"q" => query}) do
    query = query |> String.trim()

    case query do
      "" ->
        render(conn, "empty.html")

      query ->
        render(conn, "turbo-initial.html", %{query: query})
    end
  end

  #   def index(conn, %{"q" => query}) do
  #     query = query |> String.trim()
  # 
  #     case query do
  #       "" ->
  #         render(conn, "empty.html")
  # 
  #       query ->
  #         results = load_results(query)
  #         render(conn, "index.html", %{query: query, results: results})
  #     end
  #   end

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
        class:
          "mb-4 text-xl spacing-y-4 p-4 text-white bg-blue-900 border border-blue-700 rounded shadow-lg"
      )
    end
  end

  defp bundlephobia(query) do
    case Spec.search_for(:bundlephobia, query) do
      # %{"assets" => [%{"gzip" => 3920, "name" => "main", "size" => 10047, "type" => "js"}], "dependencyCount" => 0, "dependencySizes" => [%{"approximateSize" => 9537, "name" => "preact"}], "description" => "Fast 3kb React-compatible Virtual DOM library.", "gzip" => 3920, "hasJSModule" => "dist/preact.module.js", "hasJSNext" => false, "hasSideEffects" => true, "name" => "preact", "repository" => "https://github.com/preactjs/preact.git", "scoped" => false, "size" => 10047, "version" => "10.4.1"}
      %{"name" => name, "size" => size, "gzip" => size_gzip, "version" => version} ->
        emerging_3g_ms = floor(size_gzip / 50)

        # bundlephobia_url_query = URI.encode_query(%{"p" => "#{name}@#{version}"})
        bundlephobia_url_query = "p=#{name}@#{version}"
        bundlephobia_url = "https://bundlephobia.com/result?#{bundlephobia_url_query}"

        content_tag(:article, [
          h2("Bundlephobia"),
          Section.card([
            content_tag(
              :h3,
              link("#{name}@#{version}", to: bundlephobia_url),
              class: "text-2xl"
            ),
            content_tag(
              :dl,
              [
                content_tag(:dt, "Minified", class: "text-base font-bold"),
                content_tag(:dd, View.humanize_bytes(size)),
                content_tag(:dt, "Minified + Gzipped", class: "text-base font-bold"),
                content_tag(:dd, View.humanize_bytes(size_gzip)),
                content_tag(:dt, "Emerging 3G (50kB/s)", class: "text-base font-bold"),
                content_tag(:dd, "#{emerging_3g_ms}ms")
              ],
              class: "grid grid-flow-col",
              style: "grid-template-rows: repeat(2, auto);"
            )
          ])
        ])

      # %{"error" => %{"code" => "PackageNotFoundError"}} ->
      #   content_tag(:p, "Not found")

      %{"error" => _} ->
        []

      other ->
        []
    end
  end

  defp npm_downloads(query) do
    case Spec.search_for(:npm_downloads_last_month, query) do
      %{downloads_count: downloads_count, name: name} ->
        content_tag(:article, [
          h2("NPM packages"),
          Section.card([
            content_tag(
              :h3,
              link(name, to: "https://www.npmjs.com/package/#{name}"),
              class: "text-2xl"
            ),
            content_tag(
              :dl,
              [
                content_tag(:dt, "Monthly downloads", class: "text-base font-bold"),
                content_tag(:dd, View.humanize_count(downloads_count))
              ]
            )
          ])
        ])

      _ ->
        []
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
        # inspect(item),
        content_tag(:h3, title, class: "text-2xl"),
        content_tag(
          :dl,
          [
            content_tag(:dt, "Description", class: "font-bold"),
            content_tag(:dd, "#{description}"),
            case notes do
              "" ->
                []

              notes ->
                [
                  content_tag(:dt, "Notes", class: "font-bold"),
                  content_tag(:dd, "#{notes}")
                ]
            end,
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
      [] ->
        []

      results ->
        content_tag(:article, [
          h2("Can I Use"),
          CanIUse.present(results)
        ])
    end
  end

  defp html_spec(query) do
    case Spec.search_for(:whatwg_html_spec, query) do
      [] ->
        []

      :err ->
        []

      results ->
        content_tag(:article, [
          h2("HTML spec"),
          results |> present_results()
        ])
    end
  end

  defp aria_practices(query) do
    case Spec.search_for(:wai_aria_practices, query) do
      [] ->
        []

      results ->
        content_tag(:article, [
          h2("ARIA Practices"),
          Enum.map(results, fn %{heading: heading} ->
            Section.card([
              content_tag(:h3, heading)
            ])
          end)
        ])
    end
  end

  defp html_aria(query) do
    case Spec.search_for(:html_aria_spec, query) do
      [] ->
        []

      results ->
        content_tag(:article, [
          h2("HTML ARIA"),
          Enum.map(results, fn %{heading: heading, implicit_semantics: implicit_semantics} ->
            Section.card([
              content_tag(:h3, heading, class: "text-2xl"),
              content_tag(
                :dl,
                [
                  content_tag(:dt, "Implicit semantics"),
                  content_tag(:dd, "#{implicit_semantics}")
                ]
              )
            ])
          end)
        ])
    end
  end
  
  defp static(query) do
    for result <- Static.search_for(query) do
      case result do
        {:ok, name, description} ->
          Section.card([
            content_tag(:h3, name, class: "text-2xl"),
            content_tag(:p, description)
          ])
        
        _ ->
          ""
      end
    end
  end

  defp load_results(query) when is_binary(query) do
    # ComponentsGuide.Research.Source.clear_cache()
    [
      static(query),
      bundlephobia(query),
      npm_downloads(query),
      caniuse(query),
      html_spec(query),
      aria_practices(query),
      html_aria(query)
    ]
  end
end
