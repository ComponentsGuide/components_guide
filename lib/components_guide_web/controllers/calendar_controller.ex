defmodule ComponentsGuideWeb.CalendarController do
  use ComponentsGuideWeb, :controller

  def index(conn, _params) do
    today = Date.utc_today()

    assigns = [
      page_title:
        "Calendar of when important tools are released, become LTS, and reach end-of-life",
      today: today
    ]

    render(conn, "index.html", assigns)
  end
end

defmodule ComponentsGuideWeb.CalendarHTML do
  use ComponentsGuideWeb, :html
  use Phoenix.Component

  embed_templates("calendar_html/*")
end
