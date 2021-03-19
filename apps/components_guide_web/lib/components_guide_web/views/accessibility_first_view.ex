defmodule ComponentsGuideWeb.AccessibilityFirstView do
  use ComponentsGuideWeb, :view
  require EEx
  use ComponentsGuideWeb.Snippets
  use Phoenix.HTML

  def collected_image(conn, image_name) do
    %{static_path: path_to_image, width: width, height: height} = render(image_name)
    url = Routes.static_path(conn, "/" <> path_to_image)
    tag(:img, src: url, width: width / 2, height: height / 2)
  end

  def collected_figure(conn, image_name, caption) do
    content_tag(:figure, [
      collected_image(conn, image_name),
      content_tag(:figcaption, caption)
    ])
  end

  def table_rows(rows_content) do
    Enum.map(rows_content, &table_row/1)
  end

  def table_row(items) do
    content_tag(:tr, Enum.map(items, &table_cell/1))
  end

  def table_cell(content) do
    content_tag(:td, content |> line(), class: "px-3 py-1")
  end

  def header_styles() do
    color = {:lab, 47, 10, -44}

    gradient =
      Styling.linear_gradient("150grad", [
        {:lab, 47, 5, -44},
        {:lab, 47, -24, -44},
        color,
        {:lab, 47, 53, -44}
      ])

    "background-color: #{color |> Styling.to_css()}; background-image: #{gradient};"
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
