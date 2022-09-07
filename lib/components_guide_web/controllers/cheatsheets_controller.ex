defmodule ComponentsGuideWeb.CheatsheetsController do
  use ComponentsGuideWeb, :controller
  require Logger

  @wasm_source """
  (module
    (func (export "answer") (result i32)
     i32.const 42
    )
  )
  """

  def index(conn, _params) do
    render(conn, "index.html", article: "intro", wasm_source: @wasm_source)
  end

  @articles ["rxjs", "error-messages", "cloud-limits"]

  def show(conn, %{"id" => article}) when article in @articles do
    render(conn, "index.html", article: article)
  end

  def show(conn, _params) do
    raise Phoenix.Router.NoRouteError, conn: conn, router: ComponentsGuideWeb.Router
  end
end

defmodule ComponentsGuideWeb.CheatsheetsView do
  use ComponentsGuideWeb, :view
  use ComponentsGuideWeb.Snippets
  alias ComponentsGuideWeb.ThemeView

  defdelegate code_block(assigns), to: ComponentsGuideWeb.PrimitiveHelpers

  def header_styles() do
    ThemeView.banner_styles(:cheatsheets)
  end
end
