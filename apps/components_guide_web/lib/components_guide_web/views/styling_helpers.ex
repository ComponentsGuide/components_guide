defmodule ComponentsGuideWeb.StylingHelpers do
  @moduledoc """
  Conveniences for creating gradient backgrounds
  """

  # Source: https://github.com/Evercoder/culori

  defp convert_component({:linear_srgb, c}, :srgb) do
    if c > 0.0031308 do
      1.055 * :math.pow(c, 1.0 / 2.4) - 0.055
    else
      12.92 * c
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

  def convert({:xyz, x, y, z}, :srgb) do
    {
      :linear_srgb,
      x * 3.1338561 - y * 1.6168667 - 0.4906146 * z,
      x * -0.9787684 + y * 1.9161415 + 0.0334540 * z,
      x * 0.0719453 - y * 0.2289914 + 1.4052427 * z
    }
    |> convert(:srgb)
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

  def convert({:lab, _l, _a, _b} = input, :srgb) do
    convert(input, :xyz) |> convert(:srgb)
  end

  def to_css({:srgb, r, g, b}) do
    "rgba(#{(r * 255) |> round},#{(g * 255) |> round},#{(b * 255) |> round},1)"
  end

  def to_css(color_tuple) when is_tuple(color_tuple) and elem(color_tuple, 0) in [:lab] do
    color_tuple |> convert(:srgb) |> to_css()
  end

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
          ["#{color |> to_css} #{percentage}" | list]
        end,
        [],
        colors_array
      )
      |> Enum.join(",")

    "linear-gradient(#{angle}, #{colors_css})"
  end
end
