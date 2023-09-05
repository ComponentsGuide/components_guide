defmodule ComponentsGuideWeb.StylingHelpers do
  @moduledoc """
  Conveniences for creating gradient backgrounds
  """

  use Phoenix.HTML

  # Source: https://github.com/Evercoder/culori

  defp convert_component({:linear_srgb, c}, :srgb) do
    if c > 0.0031308 do
      1.055 * :math.pow(c, 1.0 / 2.4) - 0.055
    else
      12.92 * c
    end
  end

  defp convert_component({:srgb, c}, :linear_srgb) do
    if c < 0.04045 do
      c / 12.92
    else
      :math.pow((c + 0.055) / 1.055, 2.4)
    end
  end

  def convert({:linear_srgb, r, g, b}, :srgb) do
    {
      :srgb,
      convert_component({:linear_srgb, r}, :srgb),
      convert_component({:linear_srgb, g}, :srgb),
      convert_component({:linear_srgb, b}, :srgb)
    }
  end

  def convert({:xyz, x, y, z}, :linear_srgb) do
    {
      :linear_srgb,
      x * 3.1338561 - y * 1.6168667 - 0.4906146 * z,
      x * -0.9787684 + y * 1.9161415 + 0.0334540 * z,
      x * 0.0719453 - y * 0.2289914 + 1.4052427 * z
    }
  end

  def convert({:xyz, _, _, _} = input, :srgb) do
    input
    |> convert(:linear_srgb)
    |> convert(:srgb)
  end

  def convert({:srgb, r, g, b}, :linear_srgb) do
    {
      :linear_srgb,
      convert_component({:srgb, r}, :linear_srgb),
      convert_component({:srgb, g}, :linear_srgb),
      convert_component({:srgb, b}, :linear_srgb)
    }
  end

  def convert({:linear_srgb, r, g, b}, :xyz) do
    {
      :xyz,
      0.4360747 * r + 0.3850649 * g + 0.1430804 * b,
      0.2225045 * r + 0.7168786 * g + 0.0606169 * b,
      0.0139322 * r + 0.0971045 * g + 0.7141733 * b
    }
  end

  def convert({:srgb, _, _, _} = input, :xyz) do
    input |> convert(:linear_srgb) |> convert(:xyz)
  end

  @xn 0.96422
  @yn 1.00000
  @zn 0.82521

  @k :math.pow(29, 3) / :math.pow(3, 3)
  @e :math.pow(6, 3) / :math.pow(29, 3)

  def convert({:lab, l, a, b}, :xyz) do
    fy = (l + 16) / 116
    fx = a / 500 + fy
    fz = fy - b / 200

    converter = fn v ->
      cubed = :math.pow(v, 3)

      if cubed > @e do
        cubed
      else
        (116 * v - 16) / @k
      end
    end

    {
      :xyz,
      converter.(fx) * @xn,
      converter.(fy) * @yn,
      converter.(fz) * @zn
    }
  end

  def convert({:xyz, x, y, z}, :lab) do
    converter = fn v ->
      if v > @e do
        :math.pow(v, 1.0 / 3.0)
      else
        (@k * v + 16) / 116
      end
    end

    f0 = converter.(x / @xn)
    f1 = converter.(y / @yn)
    f2 = converter.(z / @zn)

    {
      :lab,
      116 * f1 - 16,
      500 * (f0 - f1),
      200 * (f1 - f2)
    }
  end

  def convert({:lab, _l, _a, _b} = input, :srgb) do
    input |> convert(:xyz) |> convert(:srgb)
  end

  def convert({:srgb, _, _, _} = input, :lab) do
    input |> convert(:xyz) |> convert(:lab)
  end

  defp clamp_0_1(n) when is_number(n), do: n |> max(0) |> min(1)

  def clamp({:srgb, r, g, b}) do
    {:srgb, r |> clamp_0_1(), g |> clamp_0_1(), b |> clamp_0_1()}
  end

  def to_css(color = {:srgb, _, _, _}, :srgb) do
    {:srgb, r, g, b} = clamp(color)
    "rgba(#{(r * 255) |> round()},#{(g * 255) |> round()},#{(b * 255) |> round()},1)"
  end

  def to_css(color, :srgb) do
    color |> convert(:srgb) |> to_css(:srgb)
  end

  def to_css({:lab, l, a, b}, :lab) do
    "lab(#{l |> round}% #{a |> round} #{b |> round})"
  end

  def to_css({:lab, l, a, b}, nil) do
    "lab(#{l |> round}% #{a |> round} #{b |> round})"
  end

  def to_css(color), do: to_css(color, :srgb)

  def linear_gradient(angle, colors) when is_list(colors) do
    linear_gradient(angle, :array.from_list(colors))
  end

  def linear_gradient(angle, colors_array) do
    true = :array.is_array(colors_array)

    max = :array.size(colors_array) - 1

    colors_css =
      :array.foldr(
        fn index, color, list ->
          percentage = "#{index / max * 100}%"
          ["#{color |> to_css(:srgb)} #{percentage}" | list]
        end,
        [],
        colors_array
      )
      |> Enum.join(", ")

    "linear-gradient(#{angle}, #{colors_css})"
  end

  def svg_linear_gradient(angle, colors, id \\ "myGradient")

  def svg_linear_gradient(angle, colors, id) when is_list(colors) do
    svg_linear_gradient(angle, :array.from_list(colors), id)
  end

  def svg_linear_gradient(angle, colors_array, id) do
    true = :array.is_array(colors_array)

    max = :array.size(colors_array) - 1

    stops =
      :array.foldr(
        fn index, color, list ->
          percentage = "#{index / max * 100}%"

          xml = ~E"""
          <stop offset="<%= percentage %>" stop-color="<%= to_css(color, :srgb) %>" />
          """

          [
            xml | list
          ]
        end,
        [],
        colors_array
      )

    ~E"""
    <linearGradient id="<%= id %>" gradientTransform="scale(1.414) <%= angle %>">
      <%= stops %>
    </linearGradient>
    """
  end
end
