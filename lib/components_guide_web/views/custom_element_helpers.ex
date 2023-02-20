defmodule ComponentsGuideWeb.CustomElementHelpers do
  use Phoenix.HTML

  def client_include(src, content \\ []), do: content_tag("include-fragment", content, src: src)
end
