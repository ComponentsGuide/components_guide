defmodule ComponentsGuideWeb.ViewSourceLive do
  use ComponentsGuideWeb,
      {:live_view, container: {:div, class: "max-w-xl mx-auto text-lg text-white pb-24"}}

  alias ComponentsGuide.Fetch

  defmodule State do
    defstruct url_string: "",
              response: nil

    def default() do
      %__MODULE__{
        url_string: "https://components.guide/"
      }
    end

    def add_response(%__MODULE__{} = state, response) do
      %__MODULE__{
        state
        | response: response,
          url_string: response.url
      }
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <h1 class="text-4xl font-bold pt-8 pb-4"><%= "Head requests" %></h1>
    <.form
      let={f}
      for={:editor}
      phx-submit="submitted"
      class="space-y-4"
    >

      <fieldset y-y y-stretch class="gap-1">
        <label for="url">Perform HEAD request for URL</label>
        <input id="url" type="url" name="url_string" value={@state.url_string} class="text-black">
      </fieldset>

      <button type="submit" class="px-3 py-1 text-blue-100 bg-blue-600 rounded">Load</button>

      <output class="block pt-2">
        <%= if @state.response do %>
          <p>HEAD <%= @state.response.url %></p>
          <p>Received <%= @state.response.status %></p>
          <p>Loaded in <%= System.convert_time_unit(@state.response.timings.duration, :native, :millisecond) %>ms</p>
          <dl class="font-mono">
            <%= for {name, value} <- @state.response.headers do %>
              <dt class="font-bold"><%= name %></dt>
              <dd class="pl-8"><%= value %></dd>
            <% end %>
          </dl>
        <% end %>
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
    assign(socket, state: state)
  end

  @impl true
  def mount(%{}, _session, socket) do
    if connected?(socket), do: :timer.send_interval(5000, self(), :update)

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

    case Fetch.Request.new(form_values["url_string"], method: "HEAD") do
      {:ok, request} ->
        response = Fetch.load!(request)
        IO.inspect(response.headers)

        state = socket.assigns.state |> State.add_response(response)

        socket = socket |> assign_state(state)
        {:noreply, socket}

      {:error, reason} ->
        {:noreply, socket}
    end
  end

  @impl true
  def handle_info(:update, socket) do
    {:noreply, socket}
  end
end
