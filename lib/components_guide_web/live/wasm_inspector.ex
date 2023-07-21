defmodule ComponentsGuideWeb.WasmInspectorLive do
  use ComponentsGuideWeb,
      {:live_view, container: {:div, class: "max-w-6xl mx-auto text-lg text-white pb-24"}}

  alias ComponentsGuide.Fetch

  @suggestions [
    "https://raw.githubusercontent.com/rsms/markdown-wasm/v1.2.0/dist/markdown.wasm",
    "https://sqlite.org/wasm/doc/trunk/jswasm/sqlite3.wasm",
    "https://unpkg.com/@automerge/automerge-wasm@0.1.25/deno/automerge_wasm_bg.wasm",
    "https://raw.githubusercontent.com/GoogleChromeLabs/squoosh/v1.12.0/codecs/oxipng/pkg/squoosh_oxipng_bg.wasm",
    "https://unpkg.com/@bokuweb/zstd-wasm@0.0.17/dist/esm/wasm/zstd.wasm",
    "https://unpkg.com/esbuild-wasm@0.17.10/esbuild.wasm"
  ]

  defmodule State do
    alias OrbWasmtime.Wasm
    defstruct wasm_bytes: nil, exports: nil

    def default() do
      %__MODULE__{}
    end

    def set_wasm_bytes(%__MODULE__{} = state, wasm_bytes) do
      exports = Wasm.list_exports({:wasm, wasm_bytes})

      %__MODULE__{
        state
        | wasm_bytes: wasm_bytes,
          exports: exports
      }
    end
  end

  @impl true
  def render(assigns) do
    assigns = Map.put(assigns, :suggestions, @suggestions)

    ~H"""
    <.form
      for={@form}
      id="wasm_inspector_form"
      phx-submit="submitted"
      class="max-w-2xl mx-auto space-y-2"
    >
      <div class="flex flex-col items-center gap-4">
        <div class="w-full">
          <.input
            field={@form[:user_url]}
            type="url"
            label="URL"
            placeholder="Enter URL to a .wasm module"
            list="url_suggestions"
          />
          <datalist id="url_suggestions">
            <option :for={suggestion <- @suggestions} value={suggestion}></option>
          </datalist>
        </div>
        <button type="submit" class="px-3 py-1 text-xl text-blue-900 bg-blue-200 rounded" autofocus>
          Load
        </button>
      </div>
    </.form>

    <output form="latency_comparison_form" class="flex flex-col gap-4 pt-4 max-w-none text-center">
      <%= if @state.wasm_bytes do %>
        <div><%= Format.humanize_bytes(byte_size(@state.wasm_bytes)) %></div>
        <dt></dt>
        <.list>
          <:item :for={{type, name} <- @state.exports} title={inspect(type)}><%= name %></:item>
        </.list>
      <% end %>
    </output>
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
  def handle_event("submitted", form_values = %{"user_url" => user_url}, socket) do
    response = user_url |> Fetch.Request.new!() |> Fetch.load!()

    state =
      socket.assigns.state
      |> State.set_wasm_bytes(response.body)

    socket =
      socket
      |> assign_state(state)
      |> assign(form: to_form(form_values))

    {:noreply, socket}
  end
end
