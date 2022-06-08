defmodule ComponentsGuideWeb.ReactEditorController do
  use ComponentsGuideWeb, :controller

  def index(conn, _params) do
    render(conn, "index.html")
  end
end

defmodule ComponentsGuideWeb.ReactEditorView do
  use ComponentsGuideWeb, :view
end
