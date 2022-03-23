defmodule ComponentsGuideWeb.ConceptsView do
  use ComponentsGuideWeb, :view
  require EEx
  use ComponentsGuideWeb.Snippets

  @hello 8

  def header_background do
    Styling.linear_gradient("150grad", [
      {:lab, 70, 40, 50},
      {:lab, 50, 90, 40},
      {:lab, 50, 90, 20},
      {:lab, 50, 90, 10},
      {:lab, 60, 70, 60},
    ])
  end

  def topic_article(assigns, block) do
    ~E"""
    <%= link to: @link do %>
      <article class="pl-8 py-4 mb-8 text-red-700 bg-red-100 border-l-4 border-current rounded hover:text-red-800 hover:bg-red-200 shadow-lg hover:shadow-xl">
        <h2 class="mb-2 text-4xl leading-normal font-bold">
          <%= @title %>
        </h2>
        <%= block[:do] %>
      </article>
    <%= end %>
    """
  end
end
