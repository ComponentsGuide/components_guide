defmodule ComponentsGuideWeb.LatencyStatusLive do
  use ComponentsGuideWeb,
      {:live_view, container: {:div, class: "max-w-6xl mx-auto text-lg text-white pb-24"}}

  alias ComponentsGuide.Fetch

  defmodule State do
    defstruct responses: nil

    def default() do
      %__MODULE__{}
    end

    def add_responses(
          %__MODULE__{} = state,
          responses = [%Fetch.Response{} | _]
        ) do
      %__MODULE__{
        state
        | responses: responses
      }
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.form
      let={f}
      for={:editor}
      id="view_source_form"
      phx-submit="submitted"
      class="max-w-2xl mt-12 mx-auto space-y-2"
    >
      <div class="flex justify-center">
        <button type="submit" class="px-3 py-1 text-xl text-blue-900 bg-blue-200 rounded" autofocus>Load</button>
      </div>
    </.form>

    <output form="view_source_form" class="flex flex-col gap-4 pt-4 max-w-none text-center">
      <%= for response <- @state.responses || [], response != nil do %>
        <div class="p-4 text-white bg-black font-mono">
          <pre class="bg-transparent"><%= response.url %></pre>
          <div class="my-1 flex justify-center">
            <div class="h-1 bg-yellow-200" style={"width: #{System.convert_time_unit(response.timings.connected, :native, :millisecond)}px"}></div>
            <div class="h-1 bg-green-500" style={"width: #{System.convert_time_unit(response.timings.received_status - response.timings.connected, :native, :millisecond)}px"}></div>
            <div class="h-1 bg-purple-200" style={"width: #{System.convert_time_unit(response.timings.duration - response.timings.received_status, :native, :millisecond)}px"}></div>
          </div>
          <p class="text-lg">
            🤝 <data class="text-yellow-200"><%= System.convert_time_unit(response.timings.connected, :native, :millisecond) %>ms</data>
            | <span class="py-1 px-1 text-green-100 bg-green-900/50 rounded"><%= response.status %></span> <data class="text-green-200">+<%= System.convert_time_unit(response.timings.received_status - response.timings.connected, :native, :millisecond) %>ms</data>
            | <span class="py-1 px-1 text-purple-100 bg-purple-900/50 rounded"><%= Format.humanize_bytes(byte_size(response.body)) %></span> body <data class="text-purple-200">+<%= System.convert_time_unit(response.timings.duration - response.timings.received_status, :native, :millisecond) %>ms</data>
          </p>
        </div>
      <% end %>
    </output>
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
  def handle_event("submitted", _form_values, socket) do
    urls = [
      "https://workers.cloudflare.com/cf.json",
      "https://api.github.com/rate_limit",
      "https://unpkg.com/robots.txt",
      "https://api.npmjs.org/downloads/point/last-month/react",
      "https://cdn.jsdelivr.net/npm/underscore@1.13.6/underscore-esm-min.js",
      "https://vercel.com/blog",
      "https://vercel.com/atom",
    ]

    responses =
      for url <- urls do
        req = Fetch.Request.new!(url)
        Fetch.load!(req)
      end

    # redis_timings = Fetch.Timings.start()
    # {duration_microseconds, _result} =
    #   :timer.tc(fn ->
    #     case Redix.command(:redix_cache, ["GET", "whatever"]) do
    #       {:ok, value} -> value
    #       _ -> nil
    #     end
    #   end)
    # redis_timings = Fetch.Timings.finish(redis_timings)
    # redis_res = Fetch.Response.new("redis:") |> Fetch.Response.add_timings(redis_timings)
    # responses = [redis_res | responses]

    state = socket.assigns.state |> State.add_responses(responses)
    socket = socket |> assign_state(state)
    {:noreply, socket}
  end
end
