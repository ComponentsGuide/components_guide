defmodule ComponentsGuideWeb.AccessibilityFirstTestingView do
  use ComponentsGuideWeb, :view
  require EEx
  use ComponentsGuideWeb.Snippets

  def header_background do
    Styling.linear_gradient("150grad", [
      {:lab, 70, 40, -50},
      {:lab, 60, -30, -50},
      {:lab, 50, 0, -80}
    ])
  end

  # def_E :topic_article, quote(do: ~E"""
  # <article class="mb-8">
  #   <h2 class="mb-2 text-4xl leading-normal text-teal-800"><%= @title %></h2>
  #   <%= block[:do] %>
  # </article>
  # """)

  # EEx.function_from_string(
  #   :def,
  #   :topic_article,
  #   """
  #   <article class="mb-8">
  #     <h2 class="mb-2 text-4xl leading-normal text-teal-800"><%= @title %></h2>
  #     <%= block[:do] %>
  #   </article>
  #   """,
  #   [:assigns, :block],
  #   engine: Phoenix.HTML.Engine
  # )

  def topic_article(assigns, block) do
    ~E"""
    <article class="mb-8">
      <h2 class="mb-2 text-4xl leading-normal text-teal-800"><%= @title %></h2>
      <%= block[:do] %>
    </article>
    """
  end

  # def topic_article(title, content_html) do
  #   <article class="mb-8">
  #     <h2 class="mb-2 text-4xl leading-normal text-teal-800">Atomic design</h2>
  #     <p>
  #       Learn how to name components. Apply the single responsibility principle. Find the indivisible component units, and compose them together into larger molecules.
  #     </p>
  #   </article>
  # end
end
