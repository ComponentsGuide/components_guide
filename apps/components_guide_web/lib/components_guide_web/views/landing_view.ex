defmodule ComponentsGuideWeb.LandingView do
  use ComponentsGuideWeb, :view

  def stack_list(items) do
    ~E"""
    <ul class="
    w-full max-w-md mx-auto
    rounded overflow-hidden
    shadow-xl
    ">
      <%= for item <- items do %>
        <%= stack_item(item) %>
      <% end %>
    </ul>
    """
  end

  defp stack_item(%{
    title: title,
    description: description,
    to: to,
    color: color
  }) do
    ~E"""
    <li>
      <a href="<%= to %>" class="
      block max-w-md w-full px-8 py-4 space-y-2
      text-<%= color %>-500 bg-<%= color %>-50
      border-t border-l-4 border-current
      hover:text-<%= color %>-600 hover:bg-<%= color %>-100
      hover:shadow-lg
      ">
        <h2 class="text-3xl font-bold leading-tight"><%= title %></h2>
        <p class="text-xl"><%= description %></p>
      </a>
    """
  end

  def header_styles(1) do
    l = 50
    color = {:lab, l, 90, 20}

    gradient = Styling.linear_gradient("150grad", [
      {:lab, 70, 40, 50},
      {:lab, 50, 90, 40},
      color,
      {:lab, 50, 90, 10},
      {:lab, 60, 70, 60},
    ])

    "background-color: #{color |> Styling.to_css()}; background-image: #{gradient};"
  end

  def header_styles(2) do
    l = 50
    a = 90
    b = 20
    color = {:lab, l, a, b}

    gradient = Styling.linear_gradient("150grad", [
      {:lab, l + 20, a * 1/2, b * 2.5},
      {:lab, l, a, b * 2},
      color,
      {:lab, l, a, b * 1/2},
      {:lab, l + 10, a * 3/4, b},
    ])

    "background-color: #{color |> Styling.to_css()}; background-image: #{gradient};"
  end

  def header_styles(3) do
    color = {:lab, 30, -20, -80} |> Styling.to_css()

    l = 20

    gradient = Styling.linear_gradient("150grad", [
      {:lab, l + 20, -40, -40},
      {:lab, l, -20, -80},
      {:lab, l - 10, 20, -80},
    ])

    "background-color: #{color}; background-image: #{gradient};"
  end

  def sections_styles(:blue) do
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

  def sections_styles(:cool) do
    color = {:lab, 30, -20, -80} |> Styling.to_css()

    l = 20

    gradient = Styling.linear_gradient("150grad", [
      {:lab, l + 20, -40, -40},
      {:lab, l, -20, -80},
      {:lab, l - 10, 20, -80},
    ])

    "background-color: #{color}; background-image: #{gradient};"
  end

  def sections_styles(:cool_light) do
    l = 75
    color = {:lab, l, -20, -80}


    gradient = Styling.linear_gradient("150grad", [
      {:lab, l + 20, -40, -40},
      {:lab, l, -20, -80},
      {:lab, l - 5, 20, -80},
    ])

    "background-color: #{color |> Styling.to_css()}; background-image: #{gradient};"
  end

  def sections_styles(:dark) do
    color = {:lab, 10, 1, -23}

    gradient = Styling.linear_gradient("150grad", [
      color,
      color,
      color,
    ])

    "background-color: #{color |> Styling.to_css()}; background-image: #{gradient};"
  end

  def sections_styles(:warm) do
    color = {:lab, 47, 10, -44}

    gradient = Styling.linear_gradient("150grad", [
      {:lab, 47, 5, -44},
      {:lab, 47, -24, -44},
      color,
      {:lab, 47, 53, -44}
    ])

    "background-color: #{color |> Styling.to_css()}; background-image: #{gradient};"
  end

  # def header_background do
  #   Styling.linear_gradient("-150grad", [
  #     {:lab, 70, 40, -50},
  #     {:lab, 60, -30, -50},
  #     {:lab, 50, 0, -80}
  #   ])
  # end
end
