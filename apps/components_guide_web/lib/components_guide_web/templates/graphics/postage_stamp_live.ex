defmodule ComponentsGuideWeb.Graphics.Live.PostageStamp do
  use ComponentsGuideWeb, :live_view

  alias ComponentsGuideWeb.StylingHelpers

  defmodule State do
    defstruct primary: "Primary", secondary: "Secondary", width: 400, height: 400, center_y: false

    def to_url(%State{primary: primary, secondary: secondary, width: width, height: height, center_y: center_y}) do
      # url = URI.parse("https://postage-stamp.collected.workers.dev/1/poster")
      url = URI.parse("https://postage-stamp.fly.dev/1/poster")
      query = [primary: primary, secondary: secondary, width: width, height: height]
      query = if center_y, do: Keyword.put(query, :centerY, ""), else: query
      url = put_in(url.query, URI.encode_query(query))
      url
    end

    def change_primary(%State{} = state, primary) do
      put_in(state.primary, primary)
    end
    
    def change_secondary(%State{} = state, secondary) do
      put_in(state.secondary, secondary)
    end
    
    def change_center_y(%State{} = state, center_y) when is_boolean(center_y) do
      put_in(state.center_y, center_y)
    end
  end

  def mount(_params, _session, socket) do
    {:ok, assign(socket, state: %State{})}
  end

  def render(assigns) do
    url = assigns.state |> State.to_url()
    
    ~L"""
    <form phx-change=change>

    <div class="flex flex-col space-y-4">

    <label class="flex flex-col">
    <span class="font-bold text-yellow-400 mr-2">Primary</span>
    <input name=primary type=text value="<%= @state.primary %>" class="text-black text-yellow-900 bg-yellow-100 px-2">
    </label>

    <label class="flex flex-col">
    <span class="font-bold text-purple-400 mr-2">Secondary</span>
    <input name=secondary type=text value="<%= @state.secondary %>" class="text-black text-purple-900 bg-purple-100 px-2">
    </label>
    
    <output>
      <img src="<%= url |> URI.to_string() %>" width="<%= @state.width %>" height="<%= @state.height %>">
      <a class="inline-block bg-blue-500 rounded-full" href="<%= url |> URI.to_string() %>">Link to image</a>
    </output>

    </div>

    </form>
    """
  end

  def handle_event(
        "change",
        changes = %{
          "primary" => primary,
          "secondary" => secondary
        },
        socket
      ) do
        IO.inspect(changes)
        
    state =
      socket.assigns.state
      |> State.change_primary(primary)
      |> State.change_secondary(secondary)
      |> State.change_center_y(Map.has_key?(changes, "centerY"))

    {
      :noreply,
      socket |> assign(:state, state)
    }
  end
end
