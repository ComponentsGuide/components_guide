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
    url = "https://cdn.jsdelivr.net/npm/typescript@4.9.5/lib/lib.dom.d.ts"
    {:ok, source} = ComponentsGuide.Research.Source.text_at(url)
    results = process_typescript_source(source)

    query = Map.get(params, "q", "")

    conn
    |> assign(:page_title, "Search DOM APIs via TypeScript’s build-in types")
    |> render("typescript.html", results: results, query: query)
  end

  def show(conn, %{"section" => "css-types"} = params) do
    url = "https://cdn.jsdelivr.net/npm/csstype@3.1.1/index.d.ts"
    {:ok, source} = ComponentsGuide.Research.Source.text_at(url)
    results = process_typescript_source(source)

    query = Map.get(params, "q", "")

    conn
    |> assign(:page_title, "Search CSS properties via TypeScript’s build-in types")
    |> render("typescript.html", results: results, query: query)
  end

  def show(conn, %{"section" => "react-types"} = params) do
    url = "https://cdn.jsdelivr.net/npm/@types/react@18.0.28/index.d.ts"
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
        View.bundlephobia(name, %{version: version, size: size, size_gzip: size_gzip})

      %{"error" => _} ->
        []

      other ->
        []
    end
  end

  defp npm_downloads(query) do
    case Spec.search_for(:npm_downloads_last_month, query) do
      %{downloads_count: downloads_count, name: name} ->
        View.npm_downloads(name, downloads_count)

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
              class: "language-ts m-2 whitespace-pre-wrap border border-violet-900 rounded"
            )
          end,
          class: "mb-4"
        )

      other ->
        content_tag(:div, inspect(other), class: "text-red-100")
    end
  end

  defmodule CanIUse do
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
        Section.card_source("Can I Use", "http://caniuse.com"),
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
      npm_downloads(query) |> Phoenix.HTML.Safe.to_iodata() |> Phoenix.HTML.raw(),
      bundlephobia(query) |> Phoenix.HTML.Safe.to_iodata() |> Phoenix.HTML.raw(),
      typescript_dom(query),
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

  defdelegate humanize_bytes(count), to: Format
  defdelegate humanize_count(count), to: Format

  defmodule Card do
    use ComponentsGuideWeb, :component

    # attr :title, :string, required: true
    attr :source, :string, required: true
    attr :source_url, :string, required: true

    slot :title
    slot :inner_block, required: true

    def card(assigns) do
      ~H"""
      <article class="relative mb-4 flex flex-col gap-4 p-4 text-xl text-white bg-violet-900/25 border border-violet-900 rounded shadow-lg">
        <h3 class="text-2xl"><%= render_slot(@title) %></h3>
        <a href={@source_url} class="hover:underline absolute top-0 right-0 mt-4 mr-4 text-sm opacity-75"><%= @source %></a>
        <%= render_slot(@inner_block) %>
      </article>
      """
    end
  end

  defmodule Section do
    def card(children) do
      content_tag(
        :article,
        children,
        class:
          "relative mb-4 flex flex-col gap-4 p-4 text-xl text-white bg-violet-900/25 border border-violet-900 rounded-lg shadow-lg"
      )
    end

    def card_source(title, href) do
      content_tag(:a, title, href: href, class: "hover:underline absolute top-0 right-0 mt-4 mr-4 text-sm opacity-75")
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
            case value do
              list when is_list(list) ->
                for item <- list, do: content_tag(:dd, item, class: "text-base pl-4")

              value ->
                content_tag(:dd, value, class: "text-base pl-4")
            end
          ])
        end)

      content_tag(:dl, children)
    end
  end

  defdelegate card(assigns), to: Card

  def npm_downloads(name, downloads_count) do
    assigns = %{name: name, downloads_count: downloads_count}

    ~H"""
    <.card source="NPM" source_url="https://www.npmjs.com/">
      <:title>npm add <%= link(@name, to: "https://www.npmjs.com/package/#{@name}") %></:title>
      <dl class="flex flex-row-reverse justify-end gap-2">
        <dt>monthly downloads</dt>
        <dd class="font-bold"><%= humanize_count(@downloads_count) %></dd>
      </dl>
    </.card>
    """
  end

  def bundlephobia(name, assigns) do
    assigns = assigns |> Map.put(:name, name)

    ~H"""
    <.card source="Bundlephobia" source_url="https://bundlephobia.com/">
      <:title>
        <.link href={"https://bundlephobia.com/result?p=#{@name}@#{@version}"}>
          <%= "#{@name}@#{@version}" %>
        </.link>
      </:title>
      <dl class="grid grid-flow-col" style="grid-template-rows: repeat(2, auto);">
        <dt>Minified</dt>
        <dd class="font-bold"><%= humanize_count(@size) %></dd>
        <dt>Minified + Gzipped</dt>
        <dd class="font-bold"><%= humanize_count(@size_gzip) %></dd>
        <dt>Emerging 3G (50kB/s)</dt>
        <dd class="font-bold"><%= floor(@size_gzip / 50) %>ms</dd>
      </dl>
    </.card>
    """

    # Section.card([
    #   Section.card_source("Bundlephobia", "https://bundlephobia.com"),
    #   content_tag(
    #     :h3,
    #     link("#{name}@#{version}", to: bundlephobia_url),
    #     class: "text-2xl"
    #   ),
    #   content_tag(
    #     :dl,
    #     [
    #       content_tag(:dt, "Minified", class: "text-base font-bold"),
    #       content_tag(:dd, humanize_bytes(size)),
    #       content_tag(:dt, "Minified + Gzipped", class: "text-base font-bold"),
    #       content_tag(:dd, humanize_bytes(size_gzip)),
    #       content_tag(:dt, "Emerging 3G (50kB/s)", class: "text-base font-bold"),
    #       content_tag(:dd, "#{emerging_3g_ms}ms")
    #     ],
    #     class: "grid grid-flow-col",
    #     style: "grid-template-rows: repeat(2, auto);"
    #   )
    # ])
  end

  defmodule Static do
    # use ComponentsGuideWeb, :view

    def render(:http_status, {name, description}) do
      Section.card([
        Section.card_source("HTTP", "https://en.wikipedia.org/wiki/List_of_HTTP_status_codes"),
        content_tag(:h3, "HTTP Status: #{name}", class: "text-2xl font-bold"),
        content_tag(:p, description)
      ])
    end

    def render(:rfc, {name, specs, metadata}) do
      Section.card([
        Section.card_source("RFC", "https://www.rfc-editor.org"),
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

    def render(:super_tiny_icon, %{name: name, url: url, urls: urls}) do
      Section.card([
        Section.card_source("Super Tiny Icons", "https://www.supertinyicons.org/"),
        content_tag(:h3, "#{name |> String.capitalize()} Icon", class: "text-2xl font-bold"),
        content_tag(
          :div,
          [
            tag(:img, src: url, width: 80, height: 80),
            Section.description_list([
              {"URL", for(url <- urls, do: link(url, to: url))},
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
