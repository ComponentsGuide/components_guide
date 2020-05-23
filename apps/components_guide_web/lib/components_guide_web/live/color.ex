defmodule ComponentsGuideWeb.ColorLive do
  use ComponentsGuideWeb, :live_view
  alias ComponentsGuideWeb.StylingHelpers

  @update_url_delay 500

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

    @lab_separator <<"~"::utf8>>

    def decode(:lab, input) when is_binary(input) do
      {l, @lab_separator <> rest} = Integer.parse(input)
      {a, @lab_separator <> rest} = Integer.parse(rest)
      {b, ""} = Integer.parse(rest)

      %__MODULE__{color: {:lab, l, a, b}}
    end

    def encode(%__MODULE__{color: color}) do
      {:lab, l, a, b} = color
      "#{l}#{@lab_separator}#{a}#{@lab_separator}#{b}"
    end

    def set_color(state = %__MODULE__{}, color), do: %{state | color: color}

    def l(%__MODULE__{color: {:lab, l, _, _}}), do: l
    def a(%__MODULE__{color: {:lab, _, a, _}}), do: a
    def b(%__MODULE__{color: {:lab, _, _, b}}), do: b

    def css_srgb(%__MODULE__{color: color}), do: StylingHelpers.to_css(color, :srgb)
    def css(%__MODULE__{color: color}), do: StylingHelpers.to_css(color, nil)

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

  defp interpolate(t, {lowest, highest}) do
    (highest - lowest) * t + lowest
  end

  def render(assigns) do
    swatch_size = 100
    {:lab, l, a, b} = assigns.state.color

    l_steps = 10

    l_gradient =
      Styling.linear_gradient(
        "150grad",
        for(n <- 0..l_steps, do: {:lab, n * (100 / l_steps), a, b})
      )

    l_gradient_svg =
      Styling.svg_linear_gradient(
        "rotate(45)",
        for(n <- 0..l_steps, do: {:lab, interpolate(n / l_steps, {0.0, 100.0}), a, b})
      )

    a_steps = 10

    a_gradient =
      Styling.linear_gradient(
        "150grad",
        for(n <- 0..a_steps, do: {:lab, l, interpolate(n / a_steps, {-127.0, 127.0}), b})
      )

    a_gradient_svg =
      Styling.svg_linear_gradient(
        "rotate(45)",
        for(n <- 0..a_steps, do: {:lab, l, interpolate(n / a_steps, {-127.0, 127.0}), b})
      )

    b_steps = 10

    b_gradient =
      Styling.linear_gradient(
        "150grad",
        for(n <- 0..b_steps, do: {:lab, l, a, interpolate(n / b_steps, {-127.0, 127.0})})
      )

    b_gradient_svg =
      Styling.svg_linear_gradient(
        "rotate(45)",
        for(n <- 0..b_steps, do: {:lab, l, a, interpolate(n / b_steps, {-127.0, 127.0})})
      )

    ~L"""
    <article class="text-2xl max-w-lg mx-auto text-white">
      <svg width="<%= swatch_size %>" height="<%= swatch_size %>" viewbox="0 0 1 1">
        <rect fill="<%= State.css_srgb(@state) %>" width="1" height="1" />
      </svg>
      <div class="flex">
        <svg viewBox="0 0 1 1" width="100" height="100">
          <defs>
            <%= l_gradient_svg %>
          </defs>
          <rect width="1" height="1" fill="url('#myGradient')" />
          <circle cx="<%= l / 100.0 %>" cy="<%= l / 100.0 %>" r="0.05" fill="white" stroke="black" stroke-width="0.01" />
        </svg>
        <svg viewBox="0 0 1 1" width="100" height="100">
          <defs>
            <%= a_gradient_svg %>
          </defs>
          <rect width="1" height="1" fill="url('#myGradient')" />
          <circle cx="<%= (a / 127.0) / 2.0 + 0.5 %>" cy="<%= (a / 127.0) / 2.0 + 0.5 %>" r="0.05" fill="white" stroke="black" stroke-width="0.01" />
        </svg>
        <svg viewBox="0 0 1 1" width="100" height="100">
          <defs>
            <%= b_gradient_svg %>
          </defs>
          <rect width="1" height="1" fill="url('#myGradient')" />
          <circle cx="<%= (b / 127.0) / 2.0 + 0.5 %>" cy="<%= (b / 127.0) / 2.0 + 0.5 %>" r="0.05" fill="white" stroke="black" stroke-width="0.01" />
        </svg>
        <!--<div style="width: 100px; height: 100px; background-image: <%= l_gradient %>"></div>-->
        <!--<div style="width: 100px; height: 100px; background-image: <%= a_gradient %>"></div>-->
        <div style="width: 100px; height: 100px; background-image: <%= b_gradient %>"></div>
        <svg width="100" height="100">
          <foreignObject>
            <div style="width: 100px; height: 100px; background-image: <%= b_gradient %>"></div>
          </foreignObject>
        </svg>
      </div>
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
        <dd><pre class="text-base whitespace-pre-wrap"><code><%= State.css_srgb(@state) %></code></pre>
        <dt class="font-bold">Gradient CSS:
        <dd><pre class="text-base whitespace-pre-wrap"><code><%= l_gradient %></code></pre>
      </dl>
    </article>
    """
  end

  def mount(_params, _session, socket) do
    {:ok, assign(socket, state: %State{}, tref: nil)}
  end

  def handle_params(%{"definition" => definition}, _path, socket) do
    state = State.decode(:lab, definition)
    {:noreply, socket |> assign(:state, state)}
  end

  def handle_params(%{}, _path, socket) do
    state = %State{}
    {:noreply, socket |> assign(:state, state)}
  end

  def handle_info(:update_url, socket) do
    state = socket.assigns.state
    encoded = State.encode(state)

    {:noreply,
     socket
     |> assign(:tref, nil)
     |> push_patch(to: Routes.color_path(socket, :lab, encoded), replace: true)}
  end

  def handle_event("lab_changed", %{"l" => l, "a" => a, "b" => b}, socket) do
    l = l |> String.to_integer()
    a = a |> String.to_integer()
    b = b |> String.to_integer()

    state = socket.assigns.state |> State.set_color({:lab, l, a, b})

    case socket.assigns.tref do
      nil -> nil
      tref -> :timer.cancel(tref)
    end

    # Throttle for Safari’s
    # SecurityError: Attempt to use history.replaceState() more than 100 times per 30 seconds
    {:ok, tref} = :timer.send_after(@update_url_delay, :update_url)

    {
      :noreply,
      socket
      |> assign(:state, state)
      |> assign(:tref, tref)
    }
  end
end
