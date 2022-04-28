defmodule ComponentsGuideWeb.WebStandards.Live.URLForm do
  use ComponentsGuideWeb, :live_view

  defmodule State do
    defstruct raw_url: "https://example.org/songs?first=20&sortBy=releaseDate"

    def to_url(%State{raw_url: raw_url}) do
      URI.parse(raw_url)
    end

    def read(%State{} = state, :query) do
      %URI{query: query} = to_url(state)
      case query do
        "" -> ""
        value -> "?" <> value
      end
    end

    def to_url_string(%State{raw_url: raw_url}) do
      URI.parse(raw_url) |> URI.to_string()
    end

    def get_query_vars(%State{} = state) do
      url = state |> to_url()
      url.query |> URI.query_decoder()
    end

    defp change_url(%State{} = state, url) do
      put_in(state.raw_url, URI.to_string(url))
    end

    def change(%State{} = state, :scheme, new_scheme) when is_binary(new_scheme) do
      url = to_url(state)
      url = put_in(url.scheme, new_scheme)
      put_in(state.raw_url, url |> URI.to_string())
    end

    def change(%State{} = state, :host, new_host) when is_binary(new_host) do
      url = to_url(state)
      url = put_in(url.host, new_host)
      IO.inspect(url)
      put_in(state.raw_url, url |> URI.to_string())
    end

    def change(%State{} = state, :path, new_path) when is_binary(new_path) do
      url = to_url(state)
      url = put_in(url.path, new_path)
      IO.inspect(url)
      put_in(state.raw_url, url |> URI.to_string())
    end

    def clear_query(%State{} = state) do
      url = to_url(state)
      url = put_in(url.query, "")
      put_in(state.raw_url, url |> URI.to_string())
    end

    def add_new_query(%State{} = state) do
      url = to_url(state)
      # url = put_in(url.query, url.query <> "&a=b")
      # url = update_in(url.query, fn query_string -> add_query_params_to(query_string, "a=b") end)
      url = update_in(url.query, &add_query_params_to(&1, "a=b"))
      put_in(state.raw_url, url |> URI.to_string())
    end

    defp add_query_params_to("", new_pair), do: new_pair
    defp add_query_params_to(query_string, new_pair), do: query_string <> "&" <> new_pair

    def change_query_vars(%State{} = state, query_vars) do
      url = to_url(state)
      url = put_in(url.query, URI.encode_query(query_vars))
      put_in(state.raw_url, url |> URI.to_string())
    end
  end

  def mount(_params, _session, socket) do
    {:ok, assign(socket, state: %State{})}
  end

  def render(assigns) do
    ~L"""
    <form phx-change=change>

    <pre class="p-4 my-2" style="color: #d6deeb;">
    <code><span class="text-yellow-400"><%= State.to_url(@state).scheme %></span>://<span class="text-green-400"><%= State.to_url(@state).host %></span><span class="text-orange-400"><%= State.to_url(@state).path %></span><span class="text-blue-400"><%= @state |> State.read(:query) %></span></code>
    </pre>

    <div class="flex flex-col space-y-4">

    <label>
    <span class="font-bold text-yellow-400 mr-2">Scheme</span>
    <input name=scheme type=text value="https" class="text-black text-yellow-900 bg-yellow-100 px-2">
    </label>

    <label>
    <span class="font-bold text-green-400 mr-2">Host</span>
    <input name=host type=text value="example.org" class="text-black text-green-900 bg-green-100 px-2">
    </label>

    <label>
    <span class="font-bold text-orange-400 mr-2">Path</span>
    <input name=path type=text value="/songs" class="text-black text-orange-900 bg-orange-100 px-2">
    </label>

    <label>
    <span class="font-bold text-blue-400 mr-2">Query</span>
    <button type=button phx-click=add-query class="px-2 bg-white text-black rounded">Add query</button>
    <button type=button phx-click=clear-query class="px-2 bg-white text-black rounded">Clear query</button>

    <div class="space-y-2 mt-2">
      <%= for {key, value} <- State.get_query_vars(@state) do %>
        <div>
          <input name=query-keys[] type=text value="<%= key %>" class="text-black text-blue-900 bg-blue-100 px-2">
          <input name=query-values[] type=text value="<%= value %>" class="text-black text-blue-900 bg-blue-100 px-2">
        </div>
      <% end %>
    </div>

    </label>

    </div>

    </form>

    <h2>Live code snippets</h2>

    <section aria-labelledby=javascript-url-heading>
    <h3 id=javascript-url-heading>JavaScript’s <code>URL</code></h3>

    <pre class="language-js" phx-hook=PreCode><code>const url = new URL(
      '<%= @state |> State.to_url() |> URI.to_string() %>'
    );
    url.protocol; // '<%= State.to_url(@state).scheme %>:'
    url.host; // '<%= State.to_url(@state).host %>'
    url.origin; // '<%= State.to_url(@state).scheme %>://<%= State.to_url(@state).host %>'
    url.pathname; // '<%= State.to_url(@state).path %>'

    url.search; // '?<%= State.to_url(@state).query %>'
    const query = new URLSearchParams(url.search);
    <%= for {key, value} <- State.get_query_vars(@state) do
      "query.get('#{key}'); // '#{value}'"
    end |> Enum.join("\n") %>
    </code></pre>
    </section>

    <section aria-labelledby=swift-url-heading>
    <h3 id=swift-url-heading>Swift’s <code>URL</code></h3>

    <pre class="language-swift" phx-hook=PreCode><code>let url = URL(
      string: "<%= @state |> State.to_url() |> URI.to_string() %>"
    )!
    url.scheme // <%= State.to_url(@state).scheme |> format(:swift_optional) %>
    url.host // <%= State.to_url(@state).host |> format(:swift_optional) %>
    url.path // "<%= State.to_url(@state).path %>"
    url.query // <%= State.to_url(@state).query |> format(:swift_optional) %>
    </code></pre>
    </section>

    <section aria-labelledby=golang-url-heading>
    <h3 id=golang-url-heading>Golang’s <code>net/url</code></h3>

    <pre class="language-go" phx-hook=PreCode><code>import (
      "log"
      "net/url"
    )

    exampleURL, err := url.Parse(
      "<%= @state |> State.to_url() |> URI.to_string() %>"
    )
    if err != nil {
      log.Fatal(err)
    }
    exampleURL.Scheme // "<%= State.to_url(@state).scheme %>"
    exampleURL.Host // "<%= State.to_url(@state).host %>"
    exampleURL.Path // "<%= State.to_url(@state).path %>"

    exampleURL.RawQuery // "<%= State.to_url(@state).query %>"
    query, err := url.ParseQuery(exampleURL.RawQuery)
    if err != nil {
      log.Fatal(err)
    }
    <%= for {key, value} <- State.get_query_vars(@state) do
      "query.Get(\"#{key}\") // \"#{value}\""
    end |> Enum.join("\n") %>
    </code></pre>
    </section>
    """
  end

  defp format(nil, :swift_optional), do: "nil"
  defp format("", :swift_optional), do: "nil"
  defp format(value, :swift_optional), do: "Optional(\"#{value}\")"

  def handle_event(
        "change",
        changes = %{
          "scheme" => new_scheme,
          "host" => new_host,
          "path" => new_path,
          "query-keys" => query_keys,
          "query-values" => query_values
        },
        socket
      ) do
    IO.inspect(changes)

    query_pairs = Enum.zip(query_keys, query_values)
    IO.inspect(query_pairs)

    state =
      socket.assigns.state
      |> State.change(:scheme, new_scheme)
      |> State.change(:host, new_host)
      |> State.change(:path, new_path)
      |> State.change_query_vars(query_pairs)

    {
      :noreply,
      socket |> assign(:state, state)
    }
  end

  def handle_event("clear-query", _, socket) do
    state =
      socket.assigns.state
      |> State.clear_query()

    {
      :noreply,
      socket |> assign(:state, state)
    }
  end

  def handle_event("add-query", _, socket) do
    state =
      socket.assigns.state
      |> State.add_new_query()

    {
      :noreply,
      socket |> assign(:state, state)
    }
  end
end
