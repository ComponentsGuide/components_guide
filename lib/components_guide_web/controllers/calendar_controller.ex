defmodule ComponentsGuideWeb.CalendarController do
  use ComponentsGuideWeb, :controller

  def index(conn, _params) do
    render(conn, :index,
      page_title:
        "Calendar of when important tools are released, become LTS, and reach end-of-life",
      today: Date.utc_today()
    )
  end
end

defmodule ComponentsGuideWeb.CalendarHTML do
  use ComponentsGuideWeb, :html

  embed_templates("calendar_html/*")
end
