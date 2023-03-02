defmodule ComponentsGuideWeb.ViewSourceLive do
  use ComponentsGuideWeb,
      {:live_view, container: {:div, class: "max-w-6xl mx-auto text-lg text-white pb-24"}}

  alias ComponentsGuide.Fetch

  defmodule State do
    defstruct url_string: "",
              request: nil,
              response: nil

    def default() do
      %__MODULE__{
        url_string: "https://components.guide/"
      }
    end

    def add_response(
          %__MODULE__{} = state,
          request = %Fetch.Request{},
          response = %Fetch.Response{}
        ) do
      %__MODULE__{
        state
        | request: request,
          response: response,
          url_string: response.url
      }
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.form
      :let={f}
      for={:editor}
      id="view_source_form"
      phx-submit="submitted"
      class="max-w-2xl mt-12 mx-auto space-y-2"
    >

      <fieldset y-y y-stretch class="gap-1">
        <label for="url">Enter URL to request:</label>
        <input id="url" type="url" name="url_string" value={@state.url_string} class="text-black">
      </fieldset>

      <div class="flex">
        <fieldset class="flex items-center gap-2">
          <label for="head-radio">
            <input id="head-radio" type="radio" name="method" value="HEAD" checked={@state.request == nil || match?(%{method: "HEAD"}, @state.request)} />
            HEAD
          </label>

          <label for="get-radio">
            <input id="get-radio" type="radio" name="method" value="GET" checked={match?(%{method: "GET"}, @state.request)} />
            GET
          </label>
        </fieldset>

        <span class="mx-auto"></span>
        <button type="submit" class="px-3 py-1 text-blue-100 bg-blue-600 rounded">Load</button>
      </div>
    </.form>

    <script type="module">
    window.customElements.define('view-source-filter', class extends HTMLElement {
      connectedCallback() {
        this.aborter = new AbortController();
        const signal = this.aborter.signal;
        this.addEventListener('input', () => {
          const listItems = this.parentNode.querySelectorAll('dl dt');
          const values = new FormData(this.querySelector('form'));
          const q = values.get('q').trim().toLowerCase();
          for (const li of Array.from(listItems)) {
            const matches = q === '' ? true : li.textContent.toLowerCase().includes(q);
            li.hidden = !matches;
          }
        }, { signal });

        this.querySelector('input').focus();
      }

      disconnectedCallback() {
        this.aborter.abort();
      }
    })
    </script>

    <output form="view_source_form" class="prose prose-invert block pt-4 max-w-none text-center">
      <%= if @state.response do %>
        <pre><%= @state.request.method %> <%= @state.response.url %></pre>
        <p>
          Received <span class="px-2 py-1 bg-green-400 text-green-900 rounded"><%= @state.response.status %></span>
          in <%= System.convert_time_unit(@state.response.timings.duration, :native, :millisecond) %>ms
        </p>
        <view-source-filter>
          <form role="search" id="filter-results">
            <input name="q" type="search" placeholder="Filter results…" class="text-white bg-gray-800 border-gray-700 rounded">
          </form>
        </view-source-filter>
        <.headers_preview headers={@state.response.headers}>
        </.headers_preview>
        <%= if (@state.response.body || "") != "" do %>
          <.body_preview content_type={Fetch.Response.find_header(@state.response, "content-type")} data={@state.response.body}>
          </.body_preview>
        <% end %>
      <% end %>
    </output>
    <style>
    dt[hidden] + dd {
      display: none;
    }
    </style>
    <script type="module">
    const lazyPrismObserver = new IntersectionObserver((entries) => {
      entries.forEach(entry => {
        if (entry.isIntersecting && !entry.target.dataset.highlighted) {
          entry.target.dataset.highlighted = '1';
          window.Prism.highlightAllUnder(entry.target);
        }
      });
    });
    window.customElements.define('lazy-prism', class extends HTMLElement {
      connectedCallback() {
        lazyPrismObserver.observe(this);
      }

      disconnectedCallback() {
        lazyPrismObserver.unobserve(this);
      }
    })
    </script>
    """
  end

  defp assign_state(socket, state) do
    assign(socket, state: state)
  end

  @impl true
  def mount(%{}, _session, socket) do
    state = State.default()
    socket = assign_state(socket, state)
    {:ok, socket}
  end

  @impl true
  def handle_event("changed", _form_values, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_event("submitted", form_values, socket) do
    # state = State.from(form_values)
    IO.inspect(form_values)
    method = Map.get(form_values, "method", "HEAD")

    case Fetch.Request.new(form_values["url_string"], method: method) do
      {:ok, request} ->
        response = Fetch.load!(request)
        IO.inspect(response.headers)

        state = socket.assigns.state |> State.add_response(request, response)

        socket = socket |> assign_state(state)
        {:noreply, socket}

      {:error, reason} ->
        {:noreply, socket}
    end
  end

  def headers_preview(assigns) do
    ~H"""
    <h2>Response Headers</h2>
    <dl class="grid grid-cols-2 gap-y-1 font-mono break-words">
      <%= for {name, value} <- @headers do %>
        <dt class="text-right font-bold"><%= name %></dt>
        <dd class="text-left pl-8"><%= value %></dd>
      <% end %>
    </dl>
    """
  end

  def body_preview(assigns) do
    ~H"""
    <%= if @content_type == "application/json" do %>
      <h2>JSON</h2>
      <lazy-prism>
        <pre class="text-left"><code class="language-json"><%= @data %></code></pre>
      </lazy-prism>
    <% end %>
    <%= if @content_type in ["text/html", "text/html; charset=utf-8"] do %>
      <.html_preview html={@data} />
    <% end %>
    """
  end

  def html_preview(assigns) do
    ~H"""
    <%= for {kind, values} <- list_html_features(@html) do %>
      <%= if kind == :link_values do %>
        <h2>Links</h2>
        <dl class="grid grid-cols-2 gap-y-1 font-mono break-words">
          <%= for {name, value} <- values do %>
            <dt class="text-right font-bold"><%= name %></dt>
            <dd class="text-left pl-8"><%= value %></dd>
          <% end %>
        </dl>
      <% end %>
      <%= if kind == :meta_values do %>
        <h2>Meta</h2>
        <dl class="grid grid-cols-2 gap-y-1 font-mono break-words">
          <%= for {name, value} <- values do %>
            <dt class="text-right font-bold"><%= name %></dt>
            <dd class="text-left pl-8"><%= value %></dd>
          <% end %>
        </dl>
      <% end %>
    <% end %>
    """
  end

  def list_html_features(html) do
    with {:ok, document} <- Floki.parse_document(html) do
      meta_values =
        for {"meta", attrs, _} <- Floki.find(document, "head meta"),
            key_value <- extract_meta_key_values(Map.new(attrs)) do
          key_value
        end

      link_values =
        for {"link", attrs, _} <- Floki.find(document, "head link"),
            key_value <- extract_link_key_values(Map.new(attrs)) do
          key_value
        end

      [meta_values: meta_values, link_values: link_values]
    else
      _ -> []
    end
  end

  def extract_link_key_values(%{"rel" => rel, "href" => href}) do
    [{rel, href}]
  end

  def extract_link_key_values(_) do
    []
  end

  def extract_meta_key_values(%{"name" => name, "content" => content}) do
    [{name, content}]
  end

  def extract_meta_key_values(%{"property" => property, "content" => content}) do
    [{property, content}]
  end

  def extract_meta_key_values(_), do: []
end
