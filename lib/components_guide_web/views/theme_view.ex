defmodule ComponentsGuideWeb.ThemeView do
  use ComponentsGuideWeb, :view

  defp gradient_styles(:green) do
    l = 62
    a = -50
    b = 20

    color = {:lab, l, a, b}

    gradient =
      Styling.linear_gradient("150grad", [
        {:lab, l * 1.5, a * 0.7, b * 2},
        {:lab, l * 1.3, a * 0.8, b * 1.6},
        {:lab, l * 1.1, a * 0.9, b * 1.2},
        color,
        {:lab, l * 0.9, a * 1.3, b * 0.7},
        {:lab, l * 0.8, a * 1.7, b * 0.5}
      ])

    "background-color: #{color |> Styling.to_css()}; background-image: #{gradient};"
  end

  defp gradient_styles(:cool_pink) do
    color = {:lab, 47, 10, -44}

    gradient =
      Styling.linear_gradient("150grad", [
        {:lab, 47, 5, -44},
        {:lab, 47, -24, -44},
        color,
        {:lab, 47, 53, -44}
      ])

    "background-color: #{color |> Styling.to_css()}; background-image: #{gradient};"
  end

  defp gradient_styles(:blue) do
    l = 0
    a = -60
    b = -90
    color = {:lab, l, a, b}

    gradient =
      Styling.linear_gradient("150grad", [
        {:lab, l * 1.1, a * 1.1, b * 1.4},
        color,
        {:lab, l * 1.3, a * 0.5, b * 0.5}
      ])

    "background-color: #{color |> Styling.to_css()}; background-image: #{gradient};"
  end

  defp gradient_styles(:orange) do
    l = 62
    a = 51
    b = 24

    color = {:lab, l, a, b}

    gradient =
      Styling.linear_gradient("150grad", [
        {:lab, l * 1.5, a * 0.7, b * 2},
        {:lab, l * 1.3, a * 0.8, b * 1.6},
        {:lab, l * 1.1, a * 0.9, b * 1.2},
        color,
        {:lab, l * 0.9, a * 1.3, b * 0.7},
        {:lab, l * 0.8, a * 1.7, b * 0.5}
      ])

    "background-color: #{color |> Styling.to_css()}; background-image: #{gradient};"
  end

  defp gradient_styles(:purple) do
    l = 50
    a = 54
    b = -85

    color = {:lab, l, a, b}

    gradient =
      Styling.linear_gradient("150grad", [
        {:lab, l * 1.5, a * 0.7, b * 2},
        {:lab, l * 1.3, a * 0.8, b * 1.6},
        {:lab, l * 1.1, a * 0.9, b * 1.2},
        color,
        {:lab, l * 0.9, a * 1.3, b * 0.7},
        {:lab, l * 0.8, a * 1.7, b * 0.5}
      ])

    "background-color: #{color |> Styling.to_css()}; background-image: #{gradient};"
  end

  defp gradient_styles(:yellow) do
    l = 65
    a = 30
    b = 120

    color = {:lab, l, a, b}

    gradient =
      Styling.linear_gradient("150grad", [
        {:lab, l * 1.5, a * 0.7, b * 2},
        {:lab, l * 1.3, a * 0.8, b * 1.6},
        {:lab, l * 1.1, a * 0.9, b * 1.2},
        color,
        {:lab, l * 0.9, a * 1.3, b * 0.7},
        {:lab, l * 0.8, a * 1.7, b * 0.5}
      ])

    "background-color: #{color |> Styling.to_css()}; background-image: #{gradient};"
  end

  def banner_styles(:accessibility_first), do: gradient_styles(:cool_pink)
  def banner_styles(:web_standards), do: gradient_styles(:green)
  def banner_styles(:robust_javascript_interactivity), do: gradient_styles(:yellow)
  def banner_styles(:composable_systems), do: gradient_styles(:orange)
  def banner_styles(:react_typescript), do: gradient_styles(:blue)
  def banner_styles(:graphics), do: gradient_styles(:purple)
  def banner_styles(:cheatsheets), do: gradient_styles(:purple)
  def banner_styles(:encoding), do: gradient_styles(:purple)
end
