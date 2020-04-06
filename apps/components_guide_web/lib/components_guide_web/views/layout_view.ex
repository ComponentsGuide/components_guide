defmodule ComponentsGuideWeb.LayoutView do
  use ComponentsGuideWeb, :view
  require EEx

  # def render("_header2.html", assigns) do
  # end

  @nav_links [
    {"By Concept", to: "/concepts"},
    {"By Technology", to: "/links"},
    {"Patterns", to: "/patterns"},
    {"Live Feed", to: "/feed"},
    {"About", to: "/about"}
  ]

  def nav_items(path_info) do
    Enum.map(@nav_links, fn
      {title, to: to} -> nav_link_item(title: title, to: to, path_info: path_info)
    end)
  end

  def nav_link_item(assigns) do
    to = assigns[:to]

    current =
      case Path.join(["/" | assigns[:path_info]]) do
        ^to -> "page"
        _ -> "false"
      end

    ~E"""
    <li><a href="<%= @to %>" aria-current="<%= current %>" class="flex h-full px-4 py-2 md:py-4 font-bold border-b-4 border-transparent hover:bg-gray-800 hover:border-red-400"><%= @title %></a>
    """
  end
end
