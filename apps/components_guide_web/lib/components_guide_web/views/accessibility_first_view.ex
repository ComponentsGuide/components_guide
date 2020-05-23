defmodule ComponentsGuideWeb.AccessibilityFirstView do
  use ComponentsGuideWeb, :view
  require EEx
  use ComponentsGuideWeb.Snippets
  use Phoenix.HTML

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
      <h2 class="mb-2 text-4xl leading-normal text-teal-800">
        <%= if Keyword.has_key?(assigns, :link) do %>
          <%= link @title, to: @link %>
        <% else %>
          <%= @title %>
        <% end %>
      </h2>
      <%= block[:do] %>
    </article>
    """
  end

  def code_block(code, type) do
    ~E"""
    <pre><code class='<%= "lang-#{type}" %>'><%= code %></code></pre>
    """
  end

  def list(items) do
    ~E"""
    <ul>
    <%= for item <- items do %>
      <li><%= line(item) %>
    <% end %>
    </ul>
    """
  end

  defmodule Theme do
    defstruct text_color: "blue"

    def h2(theme = %Theme{}, content, attrs) do
      class = "mt-8 mb-2 text-4xl leading-normal text-#{theme.text_color}-300"
      content_tag(:h2, content, [{:class, class} | attrs])
    end

    def h3(theme = %Theme{}, content, attrs) do
      class = "mt-4 mb-2 text-2xl leading-normal text-#{theme.text_color}-300"
      content_tag(:h3, content, [{:class, class} | attrs])
    end

    def h4(theme = %Theme{}, content) do
      class = "mt-4 mb-2 text-lg leading-normal text-#{theme.text_color}-300"
      content_tag(:h4, content, [{:class, class}])
    end

    def headings(theme = %Theme{}) do
      [
        fn content, attrs -> h2(theme, content, attrs) end,
        fn content, attrs -> h3(theme, content, attrs) end,
        fn content -> h4(theme, content) end
      ]
    end
  end
end
