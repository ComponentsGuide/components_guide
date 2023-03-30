defmodule ComponentsGuideWeb.WasmController do
  use ComponentsGuideWeb, :controller
  # plug :put_view, html: ComponentsGuideWeb.WasmHTML, json: ComponentsGuideWeb.WasmJSON
  alias ComponentsGuide.Rustler.Wasm
  alias ComponentsGuide.Wasm.WasmExamples

  def index(conn, _params) do
    escape_html_wat = WasmExamples.EscapeHTML.to_wat()
    html_page_wat = WasmExamples.HTMLPage.to_wat()

    render(conn, :index,
      escape_html_wat: escape_html_wat,
      html_page_wat: html_page_wat,
      today: Date.utc_today()
    )
  end

  def module(conn, %{"module" => module}) do
    wat =
      case module do
        "escape_html.wasm" -> WasmExamples.EscapeHTML.to_wat()
        "html_page.wasm" -> WasmExamples.HTMLPage.to_wat()
      end

    wasm = Wasm.wat2wasm(wat)
    # json(
    #   conn,
    #   WasmJSON.module(%{wat: wat})
    # )
    conn
    |> put_resp_content_type("application/wasm", nil)
    |> send_resp(200, wasm)
  end
end

defmodule ComponentsGuideWeb.WasmHTML do
  use ComponentsGuideWeb, :html

  embed_templates("wasm_html/*")
end

defmodule ComponentsGuideWeb.WasmJSON do
  def module(assigns) do
    %{assigns: assigns}
  end
end
