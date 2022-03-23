defmodule ComponentsGuideWeb.PageControllerTest do
  use ComponentsGuideWeb.ConnCase

  test "GET /", %{conn: conn} do
    conn = get(conn, "/")
    assert html_response(conn, 200) =~ "Components.Guide"
  end
end
