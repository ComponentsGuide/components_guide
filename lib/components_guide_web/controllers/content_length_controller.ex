defmodule ComponentsGuideWeb.ContentLengthController do
  use ComponentsGuideWeb, :controller_view
  alias ComponentsGuide.Research.Source

  @allowed_prefixes ["https://cdn.jsdelivr.net/", "https://unpkg.com/"]

  def index(conn, %{"url" => "https://cdn.jsdelivr.net/" <> _ = url}) do
    case Source.content_length(url) do
      {:ok, content_length} ->
        conn
        |> put_root_layout(false)
        |> put_layout(false)
        |> render("index.html", content_length: content_length)

      _ ->
        html(conn, "–")
    end
  end
end

defmodule ComponentsGuideWeb.ContentLengthView do
  use ComponentsGuideWeb, :view

  def render("index.html", assigns) do
    content_tag(:data, Format.humanize_bytes(assigns.content_length),
      value: assigns.content_length
    )
  end
end
