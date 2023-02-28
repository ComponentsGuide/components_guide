defmodule ComponentsGuideWeb.CalendarController do
  use ComponentsGuideWeb, :controller_view

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

defmodule ComponentsGuideWeb.CalendarView do
  use ComponentsGuideWeb, :view
  use Phoenix.Component

  alias ComponentsGuideWeb.CalendarComponent
end
