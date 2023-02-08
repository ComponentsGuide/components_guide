defmodule ComponentsGuideWeb.ResearchController do
  use ComponentsGuideWeb, :controller
  use Phoenix.HTML

  alias ComponentsGuide.Research.Spec
  alias ComponentsGuide.Research.Static
  alias ComponentsGuideWeb.ResearchView, as: View
  alias ComponentsGuideWeb.ResearchView.Section, as: Section
  alias ComponentsGuide.Research.Sources.Typescript

  defp process_typescript_source(source) do
    as_ms = &System.convert_time_unit(&1, :native, :millisecond)

    start = System.monotonic_time()
    types = Typescript.Parser.parse(source)
    duration = System.monotonic_time() - start
    IO.inspect(as_ms.(duration), label: "parse types")
    types_sources = Typescript.Parser.extract_line_ranges(source, types)
    duration = System.monotonic_time() - start
    IO.inspect(as_ms.(duration), label: "parse + extract types")

    Enum.zip_with(types, types_sources, fn type, type_source ->
      %{name: type.name, doc: type.doc, source: type_source}
    end)
  end

  def show(conn, %{"section" => "dom-types"} = params) do
    url = "https://cdn.jsdelivr.net/npm/typescript@4.7.4/lib/lib.dom.d.ts"
    {:ok, source} = ComponentsGuide.Research.Source.text_at(url)
    results = process_typescript_source(source)

    query = Map.get(params, "q", "")

    conn
    |> assign(:page_title, "Search DOM APIs via TypeScript’s build-in types")
    |> render("typescript.html", results: results, query: query)
  end

  def show(conn, %{"section" => "css-types"} = params) do
    url = "https://cdn.jsdelivr.net/npm/csstype@3.1.0/index.d.ts"
    {:ok, source} = ComponentsGuide.Research.Source.text_at(url)
    results = process_typescript_source(source)

    query = Map.get(params, "q", "")

    conn
    |> assign(:page_title, "Search CSS properties via TypeScript’s build-in types")
    |> render("typescript.html", results: results, query: query)
  end

  def show(conn, %{"section" => "react-types"} = params) do
    url = "https://cdn.jsdelivr.net/npm/@types/react@18.0.18/index.d.ts"
    {:ok, source} = ComponentsGuide.Research.Source.text_at(url)

    query = Map.get(params, "q", "")

    source =
      source
      |> String.replace("declare namespace React {", "", global: false)
      |> String.replace("\n    ", "\n")
      # |> String.trim_trailig("declare namespace React {")

    results = process_typescript_source(source)

    conn
    |> assign(:page_title, "Search React’s APIs via TypeScript’s build-in types")
    |> render("typescript.html", results: results, query: query)
  end

  # TODO: add Tailwind search e.g. "ml-4" or "ml-[5rem]" and see what is produced

  def index(conn, %{"q" => query, "results" => _}) do
    query = query |> String.trim()

    case query do
      "" ->
        render(conn, "empty.html")

      query ->
        results = load_results(query)

        conn
        |> put_root_layout(false)
        |> put_layout(false)
        |> render("results.html", %{query: query, results: results})
    end
  end

  def index(conn, %{"q" => query}) do
    query = query |> String.trim()

    case query do
      "" ->
        render(conn, "empty.html")

      query ->
        render(conn, "loading.html", %{query: query})
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
    content_tag(:h2, text, class: "text-2xl font-bold mb-4")
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

  defp bundlephobia(query) do
    IO.puts("BUNDLEPHOBIA!")

    case Spec.search_for(:bundlephobia, query) |> tap(&IO.inspect/1) do
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
          Section.card([
            content_tag(
              :h3,
              ["npm add ", link(name, to: "https://www.npmjs.com/package/#{name}")],
              class: "text-2xl"
            ),
            content_tag(
              :dl,
              [
                content_tag(:dt, "monthly downloads"),
                content_tag(:dd, View.humanize_count(downloads_count), class: "font-bold")
              ],
              class: "flex flex-row-reverse justify-end gap-2 opacity-75"
            )
          ])
        ])

      _ ->
        []
    end
  end

  defp typescript_dom(query) do
    case Spec.search_for(:typescript_dom, query) do
      {_columns, rows} ->
        content_tag(
          :div,
          for row <- rows do
            content_tag(:pre, content_tag(:code, row, class: "language-ts"),
              class: "language-ts m-2 whitespace-pre-wrap border border-indigo-700 rounded"
            )
          end,
          class: "mb-4"
        )

      other ->
        content_tag(:div, inspect(other), class: "text-red-100")
    end
  end

  defmodule CanIUse do
    # use ComponentsGuideWeb, :view
    alias ComponentsGuideWeb.ResearchView.Section, as: Section

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
             "links" => links,
             "spec" => spec,
             "status" => _status
           }
         ) do
      Section.card([
        # inspect(item),
        content_tag(:h3, link(title, to: "https://caniuse.com/#{title}"), class: "text-2xl"),
        content_tag(:p, "#{description}"),
        content_tag(:ul, [
          content_tag(:li, link("Spec", to: spec)),
          Enum.map(links, fn %{"title" => title, "url" => url} ->
            content_tag(:li, link(title, to: url))
          end)
        ]),
        content_tag(
          :dl,
          [
            case notes do
              "" ->
                []

              notes ->
                [
                  content_tag(:dt, "Notes", class: "font-bold"),
                  content_tag(:dd, "#{notes}", class: "text-base")
                ]
            end
            # content_tag(:dt, "Browsers", class: "font-bold"),
            # content_tag(:dd, "#{inspect(stats)}", class: "text-sm"),
            # content_tag(:dd, "#{inspect(item)}")
          ],
          class: "grid grid-flow-col gap-2 pt-2",
          style: "grid-template-rows: repeat(2, auto);"
        )
      ])
    end
  end

  defp caniuse(query) do
    case Spec.search_for(:caniuse, query) do
      [] ->
        []

      results when is_list(results) ->
        content_tag(:article, [
          CanIUse.present(results)
        ])

      _ ->
        nil
    end
  end

  defp html_spec(query) do
    case Spec.search_for(:whatwg_html_spec, query) do
      [] ->
        []

      :error ->
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
    Enum.map(Static.search_for(query), &View.render_static/1)
  end

  defp load_results(query) when is_binary(query) do
    # ComponentsGuide.Research.Source.clear_cache()
    [
      npm_downloads(query),
      typescript_dom(query),
      bundlephobia(query),
      caniuse(query),
      static(query)
      # html_spec(query),
      # aria_practices(query),
      # html_aria(query)
    ]
  end
end

defmodule ComponentsGuideWeb.ResearchView do
  use ComponentsGuideWeb, :view

  def results(_query) do
    ~E"""
    Content!
    """
  end

  defdelegate humanize_bytes(count), to: Format
  defdelegate humanize_count(count), to: Format

  defmodule Section do
    def card(children) do
      content_tag(
        :article,
        children,
        class:
          "mb-4 text-xl space-y-4 p-4 text-white bg-indigo-900/25 border border-indigo-900 rounded-lg shadow-lg"
      )
    end

    def unordered_list(items, attrs \\ []) do
      children =
        Enum.map(items, fn text ->
          content_tag(:li, text)
        end)

      content_tag(:ul, children, attrs)
    end

    def description_list(items) do
      children =
        items
        |> Stream.filter(fn {_title, value} -> value != nil end)
        |> Enum.map(fn {title, value} ->
          content_tag(:div, [
            content_tag(:dt, title, class: "text-base font-bold"),
            content_tag(:dd, value, class: "text-base pl-4")
          ])
        end)

      content_tag(:dl, children)
    end
  end

  defmodule Static do
    # use ComponentsGuideWeb, :view

    def render(:http_status, {name, description}) do
      Section.card([
        content_tag(:h3, "HTTP Status: #{name}", class: "text-2xl font-bold"),
        content_tag(:p, description)
      ])
    end

    def render(:rfc, {name, specs, metadata}) do
      Section.card([
        content_tag(:h3, "#{name} Spec", class: "text-2xl font-bold"),
        Section.description_list([
          {"Specs",
           specs
           |> Enum.map(&link_to_spec/1)
           |> Section.unordered_list(class: "flex list-disc ml-4 space-x-8")},
          {"Media (MIME) Type", Keyword.get(metadata, :media_type)}
        ])
      ])
    end

    def render(:super_tiny_icon, %{name: name, url: url}) do
      Section.card([
        content_tag(:h3, "#{name |> String.capitalize()} Icon", class: "text-2xl font-bold"),
        content_tag(
          :div,
          [
            tag(:img, src: url, width: 80, height: 80),
            Section.description_list([
              {"URL", link(url, to: url, class: "text-base")},
              {"Size",
               ComponentsGuideWeb.ResearchView.include_fragment(
                 "/~/content-length?" <> URI.encode_query(url: url)
               )}
            ])
          ],
          class: "flex flex-row space-x-4"
        )
      ])
    end

    def link_to_spec("rfc" <> _ = spec) do
      link(spec, to: "https://tools.ietf.org/html/" <> spec)
    end

    def link_to_spec(spec) do
      spec
    end
  end

  def render_static({type, info}) do
    Static.render(type, info)
  end
end
