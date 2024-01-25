defmodule ComponentsGuideWeb.ResearchController do
  use ComponentsGuideWeb, :controller
  use Phoenix.HTML

  alias ComponentsGuide.Research.Spec
  alias ComponentsGuide.Research.Static
  alias ComponentsGuideWeb.ResearchHTML, as: View
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
    url = "https://cdn.jsdelivr.net/npm/typescript@5.3.3/lib/lib.dom.d.ts"
    {:ok, source} = ComponentsGuide.Research.Source.text_at(url)
    results = process_typescript_source(source)

    query = Map.get(params, "q", "")

    conn
    |> assign(:page_title, "Search DOM types")
    |> render("typescript.html", results: results, query: query)
  end

  def show(conn, %{"section" => "intl-types"} = params) do
    url = "https://cdn.jsdelivr.net/npm/typescript@5.3.3/lib/lib.es2020.intl.d.ts"
    {:ok, source} = ComponentsGuide.Research.Source.text_at(url)
    results = process_typescript_source(source)

    query = Map.get(params, "q", "")

    conn
    |> assign(:page_title, "Search Intl types")
    |> render("typescript.html", results: results, query: query)
  end

  def show(conn, %{"section" => "css-types"} = params) do
    url = "https://cdn.jsdelivr.net/npm/csstype@3.1.3/index.d.ts"
    {:ok, source} = ComponentsGuide.Research.Source.text_at(url)
    results = process_typescript_source(source)

    query = Map.get(params, "q", "")

    conn
    |> assign(:page_title, "Search CSS types")
    |> render("typescript.html", results: results, query: query)
  end

  def show(conn, %{"section" => "react-types"} = params) do
    url = "https://cdn.jsdelivr.net/npm/@types/react@18.2.48/index.d.ts"
    {:ok, source} = ComponentsGuide.Research.Source.text_at(url)

    query = Map.get(params, "q", "")

    source =
      source
      |> String.replace("declare namespace React {", "", global: false)
      |> String.replace("\n    ", "\n")

    results = process_typescript_source(source)

    conn
    |> assign(:page_title, "Search React types")
    |> render("typescript.html", results: results, query: query)
  end

  # TODO: add Tailwind search e.g. "ml-4" or "ml-[5rem]" and see what is produced

  def index(conn, %{"q" => query, "results" => _}) do
    query = query |> String.trim()

    case query do
      "" ->
        render(conn, :empty)

      query ->
        results = load_results(query)

        conn
        |> put_root_layout(false)
        |> put_layout(false)
        |> render(:results, %{query: query, results: results})
    end
  end

  def index(conn, %{"q" => query}) do
    query = query |> String.trim()

    case query do
      "" ->
        render(conn, :empty)

      query ->
        render(conn, :loading, %{query: query})
    end
  end

  def index(conn, _params) do
    index(conn, %{"q" => ""})
  end

  #   defp present_results(results) when is_binary(results) do
  #     results
  #   end
  #
  #   defp present_results(results) when is_list(results) do
  #     items =
  #       results
  #       |> Enum.map(fn result -> content_tag(:li, result) end)
  #
  #     content_tag(:ul, items)
  #   end

  defp bundlephobia(query) do
    case Spec.search_for(:bundlephobia, query) |> tap(&IO.inspect/1) do
      # %{"assets" => [%{"gzip" => 3920, "name" => "main", "size" => 10047, "type" => "js"}], "dependencyCount" => 0, "dependencySizes" => [%{"approximateSize" => 9537, "name" => "preact"}], "description" => "Fast 3kb React-compatible Virtual DOM library.", "gzip" => 3920, "hasJSModule" => "dist/preact.module.js", "hasJSNext" => false, "hasSideEffects" => true, "name" => "preact", "repository" => "https://github.com/preactjs/preact.git", "scoped" => false, "size" => 10047, "version" => "10.4.1"}
      %{"name" => name, "size" => size, "gzip" => size_gzip, "version" => version} ->
        View.bundlephobia(name, %{version: version, size: size, size_gzip: size_gzip})

      %{"error" => _} ->
        []

      _other ->
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

  defp caniuse(query) do
    case Spec.search_for(:caniuse, query) do
      [] ->
        []

      results when is_list(results) ->
        View.caniuse(results)

      _ ->
        nil
    end
  end

  #   defp html_spec(query) do
  #     case Spec.search_for(:whatwg_html_spec, query) do
  #       [] ->
  #         []
  #
  #       :error ->
  #         []
  #
  #       results ->
  #         content_tag(:article, [
  #           content_tag(:h2, "HTML spec"),
  #           results |> present_results()
  #         ])
  #     end
  #   end

  defp aria_practices(query) do
    case Spec.search_for(:wai_aria_practices, query) do
      [] ->
        []

      results ->
        View.aria_practices(results)
    end
  end

  defp html_aria(query) do
    case Spec.search_for(:html_aria_spec, query) do
      [] ->
        []

      results ->
        View.html_aria(results)
    end
  end

  defp static(query) do
    for result <- Static.search_for(query) do
      result |> View.render_static() |> Phoenix.HTML.Safe.to_iodata() |> Phoenix.HTML.raw()
    end
  end

  defp load_results(query) when is_binary(query) do
    # ComponentsGuide.Research.Source.clear_cache()
    [
      npm_downloads(query),
      bundlephobia(query),
      typescript_dom(query),
      caniuse(query),
      static(query),
      # html_spec(query),
      aria_practices(query),
      html_aria(query)
    ]
    |> Enum.map(fn el -> el |> Phoenix.HTML.Safe.to_iodata() |> Phoenix.HTML.raw() end)
  end
end

defmodule ComponentsGuideWeb.ResearchHTML do
  use ComponentsGuideWeb, :html

  embed_templates("research_html/*")

  defdelegate humanize_bytes(count), to: Format
  defdelegate humanize_count(count), to: Format

  defmodule Components do
    use ComponentsGuideWeb, :component

    attr(:source, :string, required: true)
    attr(:source_url, :string, required: true)

    slot(:title)
    slot(:inner_block, required: true)

    def card(assigns) do
      ~H"""
      <article class="relative mb-4 flex flex-col gap-4 p-4 text-xl text-white bg-violet-900/25 border border-violet-900 rounded shadow-lg">
        <h3 class="pr-16 text-2xl"><%= render_slot(@title) %></h3>
        <a
          href={@source_url}
          class="hover:underline absolute top-0 right-0 mt-4 mr-4 py-1 px-3 text-sm opacity-75 bg-white/10 rounded-full"
        >
          <%= @source %>
        </a>
        <%= render_slot(@inner_block) %>
      </article>
      """
    end

    slot(:item)

    def description_list(assigns) do
      ~H"""
      <dl>
        <%= for item <- @item do %>
          <dt class="font-bold"><%= item.title %></dt>
          <%= for datum <- item[:data] || [] do %>
            <dd class="pl-4"><%= datum %></dd>
          <% end %>
          <%= if item[:inner_block] do %>
            <dd class="pl-4"><%= render_slot(item) %></dd>
          <% end %>
        <% end %>
      </dl>
      """
    end
  end

  defdelegate card(assigns), to: Components
  defdelegate description_list(assigns), to: Components

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
        <dd class="font-bold"><%= humanize_bytes(@size) %></dd>
        <dt>Minified + Gzipped</dt>
        <dd class="font-bold"><%= humanize_bytes(@size_gzip) %></dd>
        <dt>Emerging 3G (50kB/s)</dt>
        <dd class="font-bold"><%= floor(@size_gzip / 50) %>ms</dd>
      </dl>
    </.card>
    """
  end

  def caniuse(results) when is_list(results) do
    Enum.map(results, fn result ->
      caniuse_item(result) |> Phoenix.HTML.Safe.to_iodata() |> Phoenix.HTML.raw()
    end)
  end

  # From https://docs.rs/caniuse/latest/caniuse/enum.Status.html
  @caniuse_statuses_to_en %{
    "rec" => "Recommendation",
    "cr" => "Candidate Recommendation",
    "ls" => "Living Standard",
    "pr" => "Proposed Recommendation",
    "wd" => "Working Draft",
    "other" => "Other",
    "unoff" => "Unofficial"
  }

  defp caniuse_status(status) do
    @caniuse_statuses_to_en |> Map.get(status, status)
  end

  defp caniuse_markdown(source) do
    html = source |> String.trim() |> Earmark.as_html!()

    case Floki.parse_fragment(html, html_parser: Floki.HTMLParser.Mochiweb) do
      {:ok, el} ->
        el
        |> Floki.find_and_update("a[href]", fn
          {"a", [{"href", href}]} ->
            {"a", [{"href", URI.merge(URI.parse("https://caniuse2.com/"), href) |> to_string()}]}

          other ->
            other
        end)
        |> Floki.raw_html()
        |> raw()

      _ ->
        html
    end
  end

  defp caniuse_item(
         _item = %{
           "title" => title,
           "description" => description,
           "notes" => notes,
           "categories" => _categories,
           "stats" => stats,
           "links" => links,
           "spec" => spec,
           "status" => status
         }
       ) do
    assigns = %{
      title: title,
      description: description,
      notes: notes,
      links: links,
      spec: spec,
      stats: stats,
      status: status
    }

    ~H"""
    <.card source="Can I Use" source_url="https://caniuse.com">
      <:title>
        <.link href={"https://caniuse.com/#{@title}"}>
          <%= @title %>
        </.link>
      </:title>
      <%= caniuse_markdown(@description) %>
      <ul>
        <li>Status: <%= caniuse_status(@status) %></li>
        <li>
          <.link href={@spec}>Read the spec</.link>
        </li>
        <%= for link <- @links do %>
          <li>
            <.link href={link["url"]}><%= link["title"] %></.link>
          </li>
        <% end %>
      </ul>
      <dl>
        <%= if (@notes || "") != "" do %>
          <dt class="font-bold">Notes</dt>
          <dd><%= caniuse_markdown(@notes) %></dd>
        <% end %>
      </dl>
      <details>
        <summary>Browser support</summary>
        <%= inspect(@stats) %>
      </details>
    </.card>
    """
  end

  def http_status(name, description) do
    assigns = %{name: name, description: description}

    ~H"""
    <.card source="HTTP" source_url="https://en.wikipedia.org/wiki/List_of_HTTP_status_codes">
      <:title><%= "HTTP Status: #{@name}" %></:title>
      <p><%= @description %></p>
    </.card>
    """
  end

  def rfc(name, specs, metadata) do
    assigns = %{name: name, specs: specs, metadata: metadata}

    ~H"""
    <.card source="RFC" source_url="https://www.rfc-editor.org">
      <:title><%= "#{@name} Spec" %></:title>
      <.description_list>
        <:item
          title="Specs"
          data={for(spec <- @specs, do: link(spec, to: "https://tools.ietf.org/html/" <> spec))}
        />
        <:item title="Media (MIME) Type">
          <%= Keyword.get(@metadata, :media_type) %>
        </:item>
      </.description_list>
    </.card>
    """
  end

  def super_tiny_icon(%{name: _, url: _, urls: _} = assigns) do
    ~H"""
    <.card source="Super Tiny Icons" source_url="https://www.supertinyicons.org/">
      <:title><%= "#{@name |> String.capitalize()} icon" %></:title>
      <div class="flex flex-row space-x-8">
        <img src={@url} width={80} height={80} />
        <.description_list>
          <:item title="URL" data={for(url <- @urls, do: link(url, to: url))} />
          <:item title="Size">
            <%= client_include("/~/content-length?" <> URI.encode_query(url: @url), "loading…") %>
          </:item>
        </.description_list>
      </div>
    </.card>
    """
  end

  def simple_icon(%{name: _, url: _, urls: _} = assigns) do
    ~H"""
    <.card source="Simple Icons" source_url="https://simpleicons.org">
      <:title><%= "#{@name |> String.capitalize()} icon" %></:title>
      <div class="flex flex-row items-center space-x-8">
        <img
          src={@url}
          width={80}
          height={80}
          class="bg-fixed bg-repeat bg-center bg-gradient-to-br from-white via-sky-200 hover:via-white to-white max-h-max p-1"
          style="background-size: 17px 17px"
        />
        <.description_list>
          <:item title="URL" data={for(url <- @urls, do: link(url, to: url))} />
          <:item title="Size">
            <%= client_include("/~/content-length?" <> URI.encode_query(url: @url), "loading…") %>
          </:item>
        </.description_list>
      </div>
    </.card>
    """
  end

  def render_static({type, info}) do
    case type do
      :http_status ->
        {name, description} = info
        http_status(name, description)

      :rfc ->
        {name, specs, metadata} = info
        rfc(name, specs, metadata)

      :super_tiny_icon ->
        super_tiny_icon(info)

      :simple_icon ->
        simple_icon(info)
    end
  end

  def aria_practices(results) do
    assigns = %{results: results}

    ~H"""
    <%= for result <- @results do %>
      <.card source="ARIA Practices" source_url="https://www.w3.org/TR/wai-aria-practices/">
        <:title><%= result.heading %></:title>
      </.card>
    <% end %>
    """
  end

  def html_aria(results) do
    assigns = %{results: results}

    ~H"""
    <%= for result <- @results do %>
      <.card source="HTML ARIA" source_url="https://www.w3.org/TR/html-aria/">
        <:title><%= result.heading %></:title>
        <.description_list>
          <:item title="Implicit semantics">
            <%= result.implicit_semantics %>
          </:item>
        </.description_list>
      </.card>
    <% end %>
    """
  end
end
