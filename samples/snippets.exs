defmodule Implementation do
  use Phoenix.HTML
  require EEx
  import ComponentsGuideWeb.Snippets

  def topic_article_E_sigil(assigns, block) do
    ~E"""
    <article class="mb-8">
      <h2 class="mb-2 text-4xl leading-normal text-teal-800"><%= @title %></h2>
      <%= block[:do] %>
    </article>
    """
  end

  EEx.function_from_string(
    :def,
    :topic_article_function_from_string,
    ~S"""
    <article class="mb-8">
      <h2 class="mb-2 text-4xl leading-normal text-teal-800"><%= @title %></h2>
      <%= block[:do] %>
    </article>
    """,
    [:assigns, :block],
    engine: Phoenix.HTML.Engine
  )

  def_E(
    :topic_article_def_E,
    quote(
      do: ~E"""
      <article class="mb-8">
        <h2 class="mb-2 text-4xl leading-normal text-teal-800"><%= @title %></h2>
        <%= block[:do] %>
      </article>
      """
    )
  )

  def topic_article_E_sigil_static(_assigns, _block) do
    ~E"""
    <article class="mb-8">
      <h2 class="mb-2 text-4xl leading-normal text-teal-800">title</h2>
      content
    </article>
    """
  end

  @prefined ~E"""
  <article class="mb-8">
    <h2 class="mb-2 text-4xl leading-normal text-teal-800">title</h2>
    content
  </article>
  """

  def topic_article_E_sigil_static_predefined(_assigns, _block) do
    @prefined
  end

  def topic_article_content_tag(assigns, block) do
    content_tag(
      :article,
      [
        content_tag(:article, assigns[:title], class: "mb-2 text-4xl leading-normal text-teal-800"),
        block[:do]
      ],
      class: "mb-8"
    )
  end
end

Benchee.run(
  %{
    "topic_article_E_sigil" => fn ->
      Implementation.topic_article_E_sigil title: "title" do
        "content"
      end
    end,
    "topic_article_function_from_string" => fn ->
      Implementation.topic_article_function_from_string title: "title" do
        "content"
      end
    end,
    "topic_article_def_E" => fn ->
      Implementation.topic_article_def_E title: "title" do
        "content"
      end
    end,
    "topic_article_E_sigil_static" => fn ->
      Implementation.topic_article_E_sigil_static title: "title" do
        "content"
      end
    end,
    "topic_article_E_sigil_static_predefined" => fn ->
      Implementation.topic_article_E_sigil_static_predefined title: "title" do
        "content"
      end
    end,
    "topic_article_content_tag" => fn ->
      Implementation.topic_article_content_tag title: "title" do
        "content"
      end
    end
  },
  memory_time: 2
)
