defmodule ComponentsGuideWeb.WebStandards.Live.URL do
  use ComponentsGuideWeb, :live_view
  alias ComponentsGuideWeb.StylingHelpers

  defmodule State do
    defstruct raw_url: "https://example.org/songs?first=20&sortBy=releaseDate"

    def to_url(%State{raw_url: raw_url}) do
      URI.parse(raw_url)
    end

    def get_field(%State{} = state, field) when field in [:host] do
      url = state |> to_url()
      url[field]
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
  end

  def mount(_params, _session, socket) do
    {:ok, assign(socket, state: %State{})}
  end

  def render(assigns) do
    ~L"""
    <form phx-change=change>

    <pre class="p-4 my-2" style="color: #d6deeb;">
    <code><%= @state |> State.to_url() |> URI.to_string() %></code>
    </pre>

    <pre class="p-4 my-2" style="color: #d6deeb;">
    <code><span class="text-green-400"><%= State.to_url(@state).scheme %></span>://<span class="text-yellow-400"><%= State.to_url(@state).host %></span><span class="text-orange-400"><%= State.to_url(@state).path %></span><span class="text-indigo-400"/songs</span>?first=20&sortBy=releaseDate</code>
    </pre>

    <div class="flex flex-col space-y-4">

    <label>
    <span class="font-bold text-green-400 mr-2">Scheme</span>
    <input name=scheme type=text value="https" class="text-black text-green-900 bg-green-100 px-2">
    </label>

    <label>
    <span class="font-bold text-yellow-400 mr-2">Host</span>
    <input name=host type=text value="example.org" class="text-black text-yellow-900 bg-yellow-100 px-2">
    </label>

    <label>
    <span class="font-bold text-orange-400 mr-2">Path</span>
    <input name=path type=text value="/songs" class="text-black text-orange-900 bg-orange-100 px-2">
    </label>

    <label>
    <span class="font-bold text-orange-400 mr-2">Query</span>
    <button type=button class="px-2 bg-white text-black rounded">Add query</button>
    <div>
      <input name=queryKey type=text value="" class="text-black text-orange-900 bg-orange-100 px-2">
      <input name=queryValue type=text value="/songs" class="text-black text-orange-900 bg-orange-100 px-2">
    </div>
    </label>

    </div>

    </form>
    
    <pre class="language-js" phx-hook=PreCode><code>const url = new URL(
      '<%= @state |> State.to_url() |> URI.to_string() %>'
    );
    url.protocol; // <%= State.to_url(@state).scheme %>:
    url.host; // <%= State.to_url(@state).host %>:
    url.path; // <%= State.to_url(@state).path %>:
    url.search; // <%= State.to_url(@state).query %>:
    </code></pre>
    """
  end

  def handle_event(
        "change",
        %{"scheme" => new_scheme, "host" => new_host, "path" => new_path},
        socket
      ) do
    state =
      socket.assigns.state
      |> State.change(:scheme, new_scheme)
      |> State.change(:host, new_host)
      |> State.change(:path, new_path)

    {
      :noreply,
      socket |> assign(:state, state)
    }
  end
end
