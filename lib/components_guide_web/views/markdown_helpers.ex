defmodule ComponentsGuideWeb.MarkdownHelpers do
  use Phoenix.HTML

  def markdown!(markdown) do
    Earmark.as_html!(markdown)
    |> raw()
  end
end
