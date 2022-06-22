defmodule ComponentsGuideWeb.ReactTypescriptView do
  use ComponentsGuideWeb, :view

  def article_content_class("editor"), do: "content text-xl"
  def article_content_class("editor-prolog"), do: "content text-xl"
  def article_content_class(_article), do: "prose md:prose-xl prose-invert max-w-4xl mx-auto py-16"

  # def collected_image(conn, name) do
  #   %{static_path: path_to_image, width: width, height: height} = render(name)
  #   url = Routes.static_path(conn, "/" <> path_to_image)
  #   tag(:img, src: url, width: width / 2, height: height / 2)
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
end
