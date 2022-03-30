defmodule ComponentsGuideWeb.LatencyCalculatorLive do
  use ComponentsGuideWeb,
      {:live_view, container: {:div, class: "max-w-xl mx-auto text-lg text-white pb-24"}}

  defmodule State do
    defstruct uuid: nil,
              query_optimization: :full_table_scan,
              render: :server,
              user_location: :us,
              trackers_count: 2

    def default() do
      %__MODULE__{
        uuid: Ecto.UUID.generate()
      }
    end

    def from(%{
          "query_optimization" => query_optimization_value,
          "render" => render_value,
          "user_location" => user_location_value,
          "trackers_count" => trackers_count_value
        }) do
      %__MODULE__{
        query_optimization:
          case query_optimization_value do
            "full_table_scan" -> :full_table_scan
            "indexed" -> :indexed
            _ -> :full_table_scan
          end,
        render:
          case render_value do
            "server" -> :server
            "browser" -> :browser
            "server_with_browser_hydration" -> :server_with_browser_hydration
            _ -> :server
          end,
        user_location:
          case user_location_value do
            "us" -> :us
            "au" -> :au
            _ -> :us
          end,
        trackers_count:
          case trackers_count_value do
            "0" -> 0
            "2" -> 2
            "10" -> 10
            "20" -> 20
            _ -> 0
          end
      }
    end

    def regenerate(%__MODULE__{} = state) do
      %__MODULE__{state | uuid: Ecto.UUID.generate()}
    end

    @user_location_latency %{
      us: 200,
      au: 800
    }

    def line_items(%__MODULE__{} = state) do
      user_latency = @user_location_latency[state.user_location]
      cdn_duration = 100

      query_duration =
        case state.query_optimization do
          :full_table_scan -> 300
          :indexed -> 30
        end

      fetch_html_duration =
        case state.render do
          :server -> query_duration + user_latency
          :browser -> cdn_duration
          :server_with_browser_hydration -> query_duration + user_latency
        end

      fetch_api_duration =
        case state.render do
          :server -> 0
          :browser -> query_duration + user_latency
          :server_with_browser_hydration -> 0
        end

      assets_duration =
        case state.render do
          :server -> 0
          :browser -> 500
          :server_with_browser_hydration -> 500
        end

      trackers_duration = state.trackers_count * 100

      [
        fetch_html: fetch_html_duration,
        assets: assets_duration,
        fetch_api: fetch_api_duration,
        trackers: trackers_duration
      ]
    end

    def total(%__MODULE__{} = state) do
      [
        fetch_html: fetch_html,
        assets: assets,
        fetch_api: fetch_api,
        trackers: trackers
      ] = line_items(state)

      fetch_html + fetch_api + assets + trackers
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <h1 class="text-4xl font-bold pt-8 pb-4"><%= "Wait & see your latency" %></h1>
    <p class="italic pb-4">Your web request is important to us. Please hold while we serve it to your browser…</p>
    <.form
      for={:editor}
      phx-change="changed"
      class="space-y-4"
    >

      <fieldset>
        <legend>Query from the database using…</legend>
        <label><input type="radio" name="query_optimization" value="full_table_scan" checked={@state.query_optimization == :full_table_scan}> A Full Table Scan</label>
        <label><input type="radio" name="query_optimization" value="indexed"  checked={@state.query_optimization == :indexed}> An Index</label>
      </fieldset>

      <fieldset>
        <legend>Load data on…</legend>
        <label><input type="radio" name="render" value="server" checked={@state.render == :server}> USA Server</label>
        <label><input type="radio" name="render" value="browser"  checked={@state.render == :browser}> Browser</label>
        <label><input type="radio" name="render" value="server_with_browser_hydration" checked={@state.render == :server_with_browser_hydration}> USA Server with Browser Hydration</label>
      </fieldset>

      <fieldset>
        <legend>Our visitor is from…</legend>
        <label><input type="radio" name="user_location" value="us" checked={@state.user_location == :us}> USA</label>
        <label><input type="radio" name="user_location" value="au"  checked={@state.user_location == :au}> Australia</label>
      </fieldset>

      <fieldset>
        <legend>Number of trackers and analytics tools…</legend>
        <label><input type="radio" name="trackers_count" value="0" checked={@state.trackers_count == 0}> 0</label>
        <label><input type="radio" name="trackers_count" value="2"  checked={@state.trackers_count == 2}> 2</label>
        <label><input type="radio" name="trackers_count" value="10"  checked={@state.trackers_count == 10}> 10</label>
        <label><input type="radio" name="trackers_count" value="20"  checked={@state.trackers_count == 20}> 20</label>
      </fieldset>

      <output class="block pt-2">
        <p class="text-3xl font-bold"><%= @total %>ms</p>
        <div class="flex pt-4 pb-4">
          <span class="h-4 bg-green-500" style={"width: #{@line_items[:fetch_html] * 0.2}px"}></span>
          <span class="h-4 bg-orange-300" style={"width: #{@line_items[:assets] * 0.2}px"}></span>
          <span class="h-4 bg-blue-600" style={"width: #{@line_items[:fetch_api] * 0.2}px"}></span>
          <span class="h-4 bg-red-500" style={"width: #{@line_items[:trackers] * 0.2}px"}></span>
        </div>
        <ul class="flex text-sm gap-4">
          <li>
            <span class="inline-block w-3 h-3 bg-green-500"></span>
            <%= "Load HTML" %>
          </li>
          <li>
          <span class="inline-block w-3 h-3 bg-orange-300"></span>
          <%= "Load & Execute Assets" %>
          </li>
          <li>
            <span class="inline-block w-3 h-3 bg-blue-600"></span>
            <%= "Load API" %>
          </li>
          <li>
            <span class="inline-block w-3 h-3 bg-red-500"></span>
            <%= "Load & Execute Trackers" %>
          </li>
        </ul>
      </output>

    </.form>
    <style>
    :root {
      --fetch-html-color: green;
    }

    fieldset label + label { margin-left: 1rem; }
    </style>
    """
  end

  defp assign_state(socket, state) do
    total = State.total(state)
    line_items = State.line_items(state)
    assign(socket, state: state, total: total, line_items: line_items)
  end

  @impl true
  def mount(%{}, _session, socket) do
    if connected?(socket), do: :timer.send_interval(5000, self(), :update)

    state = State.default()
    socket = assign_state(socket, state)
    {:ok, socket}
  end

  @impl true
  def handle_event("changed", form_values, socket) do
    state = State.from(form_values)
    socket = assign_state(socket, state)
    {:noreply, socket}
  end

  @impl true
  def handle_info(:update, socket) do
    socket = update(socket, :state, &State.regenerate/1)
    {:noreply, socket}
  end
end
