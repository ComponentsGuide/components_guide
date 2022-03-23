defmodule ComponentsGuideWeb.ElementsView do
  use ComponentsGuideWeb, :view
end

defmodule ComponentsGuideWeb.ElementsController do
  use ComponentsGuideWeb, :controller
  
  plug :put_root_layout, "turbo.html"
  plug :put_layout, false
  plug :put_view, ComponentsGuideWeb.IntegrationsView

  def index(conn, %{"element_id" => "convertkit-form"}) do
    conn = merge_assigns(conn, frame_id: "convertkit-form")
    # conn = put_root_layout(conn, false)
    # conn = put_layout(conn, false)
    # rendered = Phoenix.View.render(ComponentsGuideWeb.IntegrationsView, "convertkit_form.html", [])
    # conn |> html(rendered)
    render(conn, "convertkit_form.html")
  end
  
  def index(conn, params) do
    conn |> html("hello #{inspect(params)}")
  end
end
