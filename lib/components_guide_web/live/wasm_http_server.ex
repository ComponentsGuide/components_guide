defmodule ComponentsGuideWeb.WasmHTTPServerLive do
  use ComponentsGuideWeb,
      {:live_view, container: {:div, class: "max-w-6xl mx-auto text-lg text-white pb-24"}}

  alias ComponentsGuide.Fetch
  alias ComponentsGuide.Wasm.Instance
  alias ComponentsGuide.Wasm.Examples.HTTPServer.PortfolioSite

  @suggestions [
    "/",
    "/about",
    "/foo"
  ]

  defmodule State do
    alias ComponentsGuide.Wasm
    defstruct status: nil, body: nil

    def default() do
      %__MODULE__{}
    end

    def set_status(%__MODULE__{} = state, status) do
      put_in(state.status, status)
    end

    def set_body(%__MODULE__{} = state, body) do
      put_in(state.body, body)
    end
  end

  @impl true
  def render(assigns) do
    assigns = Map.put(assigns, :suggestions, @suggestions)

    ~H"""
    <.form
      for={@form}
      id="wasm_http_server_form"
      phx-submit="submitted"
      class="max-w-2xl mx-auto space-y-2"
    >
      <div class="flex flex-col items-center gap-4">
        <div class="w-full">
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
        <button type="submit" class="px-3 py-1 text-xl text-blue-900 bg-blue-200 rounded" autofocus>
          View
        </button>
      </div>
    </.form>

    <output form="latency_comparison_form" class="flex flex-col gap-4 pt-4 max-w-none text-center">
      <%= if @state.status do %>
        <p>Status: <%= @state.status %></p>
      <% end %>
      <%= if @state.body do %>
        <pre><%= @state.body %></pre>
      <% end %>
    </output>

    <wasm-html src="/wasm/module/counter_html.wasm" class="block" id="wasm-html-1" phx-update="ignore">
      <div>Loading…</div>
    </wasm-html>
    """
  end

  defp assign_state(socket, state), do: assign(socket, state: state)

  @impl true
  def mount(_params, _session, socket) do
    state = State.default()

    socket =
      socket
      |> assign(page_title: "Wasm Inspector")
      |> assign_state(state)
      |> assign(form: to_form(%{}))

    {:ok, socket}
  end

  @impl true
  def handle_event("submitted", form_values = %{"user_path" => user_path}, socket) do
    inst = PortfolioSite.start()

    Instance.call(inst, :set_method, Instance.alloc_string(inst, "GET"))
    Instance.call(inst, :set_path, Instance.alloc_string(inst, user_path))

    status = Instance.call(inst, :get_status)
    body = Instance.call_reading_string(inst, :get_body)

    state =
      socket.assigns.state
      |> State.set_status(status)
      |> State.set_body(body)

    socket =
      socket
      |> assign_state(state)
      |> assign(form: to_form(form_values))

    {:noreply, socket}
  end
end
