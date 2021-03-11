defmodule ComponentsGuideWeb.ContentLengthController do
  use ComponentsGuideWeb, :controller
  alias ComponentsGuide.Research.Source
  alias ComponentsGuideWeb.ResearchView, as: View

  def index(conn, _params) do
    url = "https://unpkg.com/super-tiny-icons@0.4.0/images/svg/twitter.svg"

    case Source.content_length(url) do
      {:ok, content_length} ->
        conn
        |> put_root_layout(false)
        |> put_layout(false)
        |> render("index.html", content_length: content_length)

      _ ->
        html(conn, "")
    end
  end
end

defmodule ComponentsGuideWeb.ContentLengthView do
  use ComponentsGuideWeb, :view

  def render("index.html", assigns) do
    turbo_frame("content-length") do
      content_tag(:data, "#{assigns.content_length}", value: assigns.content_length)
    end
  end
end
