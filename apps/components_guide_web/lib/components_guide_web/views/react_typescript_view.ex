defmodule ComponentsGuideWeb.ReactTypescriptView do
  use ComponentsGuideWeb, :view

  def header_styles() do
    l = 50
    l = 0
    a = -60
    b = -90
    color = {:lab, l, a, b}

    gradient = Styling.linear_gradient("150grad", [
      {:lab, l * 1.1, a * 1.1, b * 1.4},
      color,
      {:lab, l * 1.3, a * 0.5, b * 0.5},
    ])

    "background-color: #{color |> Styling.to_css()}; background-image: #{gradient};"
  end
end
