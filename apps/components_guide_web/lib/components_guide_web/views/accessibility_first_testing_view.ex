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

  def topic_article(assigns, block) do
    ~E"""
    <article class="mb-8">
      <h2 class="mb-2 text-4xl leading-normal text-teal-800"><%= @title %></h2>
      <%= block[:do] %>
    </article>
    """
  end

  def code_block(code, type) do
    ~E"""
    <pre><code class='<%= "lang-#{type}" %>'><%= code %></code></pre>
    """
  end
end
