defmodule ComponentsGuideWeb.FakeSearchController do
  use ComponentsGuideWeb, :controller

  alias ComponentsGuide.FakeSearch

  def index(conn, _params) do
    items = FakeSearch.list()
    render(conn, "index.html", items: items)
  end
end
