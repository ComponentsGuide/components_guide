defmodule ComponentsGuideWeb.LayoutView do
  use ComponentsGuideWeb, :view
  require EEx

  # def render("_header2.html", assigns) do
  # end

  @nav_links [
    {"By Concept", to: "/concepts"},
    {"By Technology", to: "/links"},
    {:search},
    # {"Patterns", to: "/patterns"},
    {"Live Feed", to: "/feed"},
    {"About", to: "/about"}
  ]

  defp search_form do
    ~E"""
    <li>
      <form role=search action="/research" class="flex h-full px-2 items-center">
        <input type=text name=q placeholder="Search" class="w-full py-1 px-2 bg-white text-black">
      </form>
    """
  end

  def nav_items(path_info) do
    [
      Enum.map(@nav_links, fn
        {:search} -> search_form()
        {title, to: to} -> nav_link_item(title: title, to: to, path_info: path_info)
      end)
    ]
  end

  def nav_link_item(assigns) do
    to = assigns[:to]

    current =
      case Path.join(["/" | assigns[:path_info]]) do
        ^to -> "page"
        _ -> "false"
      end

    ~E"""
    <li><a href="<%= @to %>" aria-current="<%= current %>" class="flex h-full px-4 py-2 md:py-2 font-bold border-4 border-transparent hover:bg-gray-800 hover:border-white"><%= @title %></a>
    """
  end
end
