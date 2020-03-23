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
    <article class="mb-8">
      <h2 class="mb-2 text-4xl leading-normal font-bold text-red-700"><%= @title %></h2>
      <%= block[:do] %>
    </article>
    """
  end
end
