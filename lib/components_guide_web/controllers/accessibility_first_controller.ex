defmodule ComponentsGuideWeb.AccessibilityFirstController do
  use ComponentsGuideWeb, :controller_view
  require Logger

  def index(conn, _params) do
    conn
    |> assign(:page_title, page_title(nil))
    |> render("index.html", article: "intro")
  end

  @articles [
    "navigation",
    "landmarks",
    "roles",
    "accessible-name",
    "forms",
    "content",
    "refactoring-accessibility",
    "playwright"
  ]

  def show(conn, %{"id" => article}) when article in @articles do
    conn
    |> assign(:page_title, page_title(article))
    |> render("index.html", article: article)
  end

  def show(conn, %{"id" => "widgets-cheatsheet"}) do
    conn
    |> assign(:page_title, "Accessible Widgets Cheatsheet")
    |> render("widgets-cheatsheet.html")
  end

  def show(conn, %{"id" => "properties-cheatsheet"}) do
    conn
    |> assign(:page_title, "Accessible Properties Cheatsheet")
    |> render("properties-cheatsheet.html")
  end

  def show(conn, _params) do
    raise Phoenix.Router.NoRouteError, conn: conn, router: ComponentsGuideWeb.Router
  end

  defp page_title("navigation"), do: "Accessibility-First Navigation"
  defp page_title("landmarks"), do: "Accessibility-First Landmarks"
  defp page_title("roles"), do: "Accessibility-First Roles"
  defp page_title("forms"), do: "Accessibility-First Forms"
  defp page_title("content"), do: "Accessibility-First Content"
  defp page_title("accessible-name"), do: "Learning Accessible Names"
  defp page_title("refactoring-accessibility"), do: "Refactoring Accessibility"
  defp page_title("playwright"), do: "Accessibility Testing in Playwright"
  defp page_title(_), do: "Accessibility-First Development"
end

defmodule ComponentsGuideWeb.AccessibilityFirstView do
  use ComponentsGuideWeb, :view
  require EEx
  use ComponentsGuideWeb.Snippets

  # def collected_image(conn, image_name) do
  #   %{static_path: path_to_image, width: width, height: height} = render(image_name)
  #   url = Routes.static_path(conn, "/" <> path_to_image)
  #   tag(:img, src: url, width: width / 2, height: height / 2)
  # end

  # def collected_figure(conn, image_name, caption) do
  #   content_tag(:figure, [
  #     collected_image(conn, image_name),
  #     content_tag(:figcaption, caption)
  #   ])
  # end

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

  def ul_list(items) do
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

    def h2(_theme = %Theme{}, content, attrs) do
      # class = "mt-8 mb-2 text-4xl leading-normal text-#{theme.text_color}-300"
      class = ""
      content_tag(:h2, content, [{:class, class} | attrs])
    end

    def h3(_theme = %Theme{}, content, attrs) do
      # class = "mt-4 mb-2 text-2xl leading-normal text-#{theme.text_color}-300"
      class = ""
      content_tag(:h3, content, [{:class, class} | attrs])
    end

    def h4(_theme = %Theme{}, content) do
      # class = "mt-4 mb-2 text-lg leading-normal text-#{theme.text_color}-300"
      class = ""
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
