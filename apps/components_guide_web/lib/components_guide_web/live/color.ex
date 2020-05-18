defmodule ComponentsGuideWeb.ColorLive do
  use ComponentsGuideWeb, :live_view
  alias ComponentsGuideWeb.StylingHelpers

  defmodule State do
    defstruct color: {:lab, 50, 100, -128}

    def decode(
          "#" <>
            <<r1::utf8>> <>
            <<r2::utf8>> <> <<g1::utf8>> <> <<g2::utf8>> <> <<b1::utf8>> <> <<b2::utf8>>
        ) do
      # <<cp::utf8>>
      r = <<r1::utf8>> <> <<r2::utf8>>
      g = <<g1::utf8>> <> <<g2::utf8>>
      b = <<b1::utf8>> <> <<b2::utf8>>

      r = String.to_integer(r, 16) / 255
      g = String.to_integer(g, 16) / 255
      b = String.to_integer(b, 16) / 255

      color = {:srgb, r, g, b} |> Styling.convert(:lab)

      IO.puts("INPUT #{r} #{g} #{b} OUTPUT #{inspect(color)}")
      %State{color: color}
    end

    def decode(:lab, input) when is_binary(input) do
      {l, <<","::utf8>> <> rest} = Integer.parse(input)
      {a, <<","::utf8>> <> rest} = Integer.parse(rest)
      {b, ""} = Integer.parse(rest)

      %__MODULE__{color: {:lab, l, a, b}}
    end

    def encode(%__MODULE__{color: color})  do
      {:lab,l,a,b} = color
      "#{l},#{a},#{b}"
    end

    def set_color(state = %__MODULE__{}, color), do: %{state | color: color}

    def l(%__MODULE__{color: {:lab, l, _, _}}), do: l
    def a(%__MODULE__{color: {:lab, _, a, _}}), do: a
    def b(%__MODULE__{color: {:lab, _, _, b}}), do: b

    def css(%__MODULE__{color: color}), do: StylingHelpers.to_css(color)

    defp to_srgb(%__MODULE__{color: color}) do
      {:srgb, r, g, b} = color |> StylingHelpers.convert(:srgb) |> StylingHelpers.clamp()
      {r, g, b}
    end

    def hex(state = %__MODULE__{}) do
      {r, g, b} = state |> to_srgb()

      digits =
        [r, g, b]
        |> Enum.map(fn c ->
          round(c * 255) |> Integer.to_string(16) |> String.pad_leading(2, "0")
        end)
        |> Enum.join()

      "##{digits}"
    end
  end

  def render(assigns) do
    swatch_size = 100
    {:lab, l, a, b} = assigns.state.color

    gradient =
      Styling.linear_gradient("150grad", [
        {:lab, l * 1.5, a * 1.2, b * 0.8},
        {:lab, l, a, b},
        {:lab, l * 0.5, a * 0.8, b * 1.2}
      ])

    ~L"""
    <article class="text-2xl max-w-lg mx-auto text-white">
      <svg width="<%= swatch_size %>" height="<%= swatch_size %>" viewbox="0 0 1 1">
        <rect fill="<%= State.hex(@state) %>" width="1" height="1" />
      </svg>
      <div style="width: 100px; height: 100px; background-image: <%= gradient %>"></div>
      <form phx-change="lab_changed" class="flex flex-col">
        <label>
          L
          <input type=range name=l min="0" max="100" value="<%= State.l(@state) %>" phx-value-component=l>
          <span><%= l %></span>
        </label>
        <label>
          a
          <input type=range name=a min="-128" max="127" value="<%= State.a(@state) %>" phx-value-component=a>
          <span><%= a %></span>
        </label>
        <label>
          b
          <input type=range name=b min="-128" max="127" value="<%= State.b(@state) %>" phx-value-component=b>
          <span><%= b %></span>
        </label>
      </form>
      <dl>
        <dt class="font-bold">Hex:
        <dd><%= State.hex(@state) %>
        <dt class="font-bold">CSS:
        <dd><pre class="text-base whitespace-pre-wrap"><code><%= State.css(@state) %></code></pre>
        <dt class="font-bold">Gradient CSS:
        <dd><pre class="text-base whitespace-pre-wrap"><code><%= gradient %></code></pre>
      </dl>
    </article>
    """
  end

  def mount(_params, _session, socket) do
    {:ok, assign(socket, state: %State{})}
  end

  def handle_params(%{"definition" => definition}, _path, socket) do
    state = State.decode(:lab, definition)
    {:noreply, socket |> assign(:state, state)}
  end

  def handle_params(%{}, _path, socket) do
    state = %State{}
    {:noreply, socket |> assign(:state, state)}
  end

  def handle_event("lab_changed", %{"l" => l, "a" => a, "b" => b}, socket) do
    l = l |> String.to_integer()
    a = a |> String.to_integer()
    b = b |> String.to_integer()

    state = socket.assigns.state |> State.set_color({:lab, l, a, b})
    encoded = State.encode(state)

    # TODO: throttle for Safari’s
    # SecurityError: Attempt to use history.replaceState() more than 100 times per 30 seconds
    {:noreply,
     socket
     |> push_patch(to: Routes.color_path(socket, :lab, encoded), replace: true)}
  end
end
