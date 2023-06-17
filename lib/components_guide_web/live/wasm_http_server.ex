defmodule ComponentsGuideWeb.WasmHTTPServerLive do
  use ComponentsGuideWeb,
      {:live_view,
       container:
         {:div, class: "max-w-6xl mx-auto px-3 prose prose-invert text-lg text-white pb-24"}}

  alias ComponentsGuide.Wasm
  alias ComponentsGuide.Wasm.Examples.HTTPServer.PortfolioSite

  @suggestions [
    "/",
    "/about",
    "/foo"
  ]

  defmodule State do
    defstruct status: nil, body: nil

    alias Wasm.Instance

    def default() do
      %__MODULE__{}
    end

    def set_status(%__MODULE__{} = state, status) do
      put_in(state.status, status)
    end

    def set_body(%__MODULE__{} = state, body) do
      put_in(state.body, body)
    end

    def apply_input(%__MODULE__{} = state, method, path) do
      inst = Wasm.Instance.run(PortfolioSite)

      Instance.call(inst, :set_method, Instance.alloc_string(inst, method))
      Instance.call(inst, :set_path, Instance.alloc_string(inst, path))

      status = Instance.call(inst, :get_status)
      body = Instance.call_reading_string(inst, :get_body)

      state
      |> set_status(status)
      |> set_body(body)
    end
  end

  @impl true
  def render(assigns) do
    assigns = Map.put(assigns, :suggestions, @suggestions)

    ~H"""
    <.form
      for={@form}
      id="wasm_http_server_form"
      phx-change="submitted"
      class="max-w-2xl mx-auto space-y-2"
    >
      <h2>On server:</h2>
      <div class="flex flex-col items-start gap-4">
        <.input
          field={@form[:user_method]}
          type="text"
          label="Method"
          value="GET"
          placeholder="Enter HTTP method e.g. GET"
        />
        <.input
          field={@form[:user_path]}
          type="text"
          label="Path"
          value="/about"
          placeholder="Enter path"
          list="path_suggestions"
        />
        <datalist id="path_suggestions">
          <option :for={suggestion <- @suggestions} value={suggestion}></option>
        </datalist>
      </div>
    </.form>

    <output form="wasm_http_server_form" class="not-prose block pt-4">
      <%= if @state.status do %>
        <p>Status: <%= @state.status %></p>
      <% end %>
      <%= if @state.body do %>
        <pre><code class="lang-html"><%= @state.body %></code></pre>
      <% end %>
    </output>

    <h2>In browser:</h2>

    <wasm-http-server
      src="/wasm/module/website_portfolio.wasm"
      class="block"
      id="wasm-html-1"
      phx-update="ignore"
    >
      <form class="flex flex-col text-left gap-2">
        <div class="flex flex-col items-start gap-4">
          <.input
            name="set_method"
            type="text"
            label="Method"
            value="GET"
            placeholder="Enter HTTP method e.g. GET"
          />
          <.input name="set_path" type="text" label="Path" value="/about" placeholder="Enter path" />
        </div>
        <output class="not-prose pt-4">
          <p>Status: <span slot="get_status"></span></p>
          <pre><code class="lang-html"><span slot="get_body"></span></code></pre>
        </output>
      </form>
    </wasm-http-server>

    <p>Wasm Bytes: <%= byte_size(Wasm.to_wasm(PortfolioSite)) %></p>
    """
  end

  defp assign_state(socket, state), do: assign(socket, state: state)

  @impl true
  def mount(_params, _session, socket) do
    state = State.default() |> State.apply_input("GET", "/")

    socket =
      socket
      |> assign(page_title: "Wasm Inspector")
      |> assign_state(state)
      |> assign(form: to_form(%{}))

    {:ok, socket}
  end

  @impl true
  def handle_event(
        "submitted",
        form_values = %{"user_method" => user_method, "user_path" => user_path},
        socket
      ) do
    state =
      socket.assigns.state
      |> State.apply_input(user_method, user_path)

    socket =
      socket
      |> assign_state(state)
      |> assign(form: to_form(form_values))

    {:noreply, socket}
  end
end
