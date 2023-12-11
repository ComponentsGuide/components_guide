defmodule ComponentsGuideWeb.BrowserCompatLive do
  use ComponentsGuideWeb,
      {:live_view, container: {:div, class: "max-w-6xl mx-auto text-lg text-white pb-24"}}

  alias ComponentsGuide.Fetch
  alias ComponentsGuideWeb.BrowserCompatComponents, as: Components

  @data_url "https://unpkg.com/@mdn/browser-compat-data@5.4.5/data.json"
  # https://nodejs.org/en/blog
  # https://nodejs.org/en/feed/blog.xml

  defmodule State do
    defstruct data: nil

    def default(), do: %__MODULE__{}

    def add_response(
          %__MODULE__{} = state,
          response = %Fetch.Response{}
        ) do
      data = Jason.decode!(response.body)
      %__MODULE__{state | data: data}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.form
      :let={f}
      for={:editor}
      id="browser_compat_form"
      phx-submit="submitted"
      class="max-w-2xl mt-12 mx-auto space-y-2"
    >
      <div class="flex">
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
      <%= if @state.data do %>
        <pre><%= inspect(Map.keys(@state.data), pretty: true) %></pre>
        <Components.html_element
          title="<search>"
          tag="search"
          data={@state.data["html"]["elements"]["search"]}
        />
        <details>
          <summary>Browsers</summary>
          <pre><%= inspect(@state.data["browsers"], pretty: true) %></pre>
        </details>
        <pre><%= inspect(Map.keys(@state.data["html"]), pretty: true) %></pre>
        <pre><%= inspect(Map.keys(@state.data["html"]["elements"]), pretty: true) %></pre>
        <pre><%= inspect(@state.data["html"]["elements"]["search"], pretty: true) %></pre>
        <pre><%= inspect(Map.keys(@state.data["html"]["global_attributes"]), pretty: true) %></pre>
        <pre><%= inspect(Map.keys(@state.data["http"]["headers"]), pretty: true) %></pre>
        <pre><%= inspect(Map.keys(@state.data["http"]["status"]), pretty: true) %></pre>
        <pre><%= inspect(Map.keys(@state.data["webassembly"]), pretty: true) %></pre>
        <pre><%= inspect(Map.keys(@state.data["css"]), pretty: true) %></pre>
        <pre><%= inspect(Map.keys(@state.data["javascript"]), pretty: true) %></pre>
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

  defp result(value, first_elem) when is_atom(first_elem) do
    {first_elem, value}
  end

  defp set_state(socket, updater) when is_function(updater, 1) do
    update(socket, :state, updater)
  end

  defp set_state(socket, state) do
    assign(socket, :state, state)
  end

  @impl true
  def mount(%{}, _session, socket) do
    # socket = set_state(socket, State.default())
    # {:ok, socket}
    socket |> set_state(State.default()) |> result(:ok)
  end

  @impl true
  def handle_event("submitted", _form_values, socket) do
    case Fetch.Request.new(@data_url, method: "GET") do
      {:ok, request} ->
        response = Fetch.load!(request)
        # socket = socket |> set_state(&State.add_response(&1, response))
        socket =
          set_state(socket, fn state ->
            state |> State.add_response(response)
          end)

        {:noreply, socket}

      {:error, _reason} ->
        {:noreply, socket}
    end
  end
end
