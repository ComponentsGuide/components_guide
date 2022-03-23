defmodule ComponentsGuideWeb.ComposableSystemsView do
  use ComponentsGuideWeb, :view
  require EEx

  def header_styles() do
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
end
