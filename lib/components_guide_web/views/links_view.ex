defmodule ComponentsGuideWeb.LinksView do
  use ComponentsGuideWeb, :view
  alias Phoenix.HTML.Tag
  alias Phoenix.HTML.Link

  # def defsection(name, tag_name, attrs) do
  #   Tag.content_tag(tag_name, "hello", attrs)
  # end

  def article(attrs \\ [], do: block) do
    # %{class: class} = Enum.into(attrs, %{class: ""})
    class = Keyword.get(attrs, :class, "")

    Tag.content_tag :article, class: "mt-8 mb-24 #{class} a{font-bold}" do
      block
    end
  end

  def span(content, options) when is_list(options) do
    content_tag(:span, content, Enum.reduce(options, [class: ""], &span_option/2))
  end

  defp span_option(:nums_tabular, tag_options) do
    Keyword.update!(tag_options, :class, fn class ->
      class <> " nums-tabular"
    end)
  end

  defp list_item({{:safe, content}, nested_items}) when is_list(nested_items) do
    content_tag(:li) do
      [
        {:safe, content},
        ul_list(nested_items)
      ]
    end
  end

  defp list_item({:safe, content}) do
    content_tag(:li, {:safe, content})
  end

  def ul_list(items) when is_list(items) do
    content_tag(:ul, Enum.map(items, &list_item/1))
  end

  def nums_tabular(content) do
    content_tag(:span, content, class: "nums-tabular")
  end
end
