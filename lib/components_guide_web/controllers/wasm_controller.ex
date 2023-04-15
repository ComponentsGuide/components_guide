defmodule ComponentsGuideWeb.WasmController do
  use ComponentsGuideWeb, :controller
  # plug :put_view, html: ComponentsGuideWeb.WasmHTML, json: ComponentsGuideWeb.WasmJSON
  alias ComponentsGuide.Rustler.Wasm
  alias ComponentsGuide.Wasm.WasmExamples

  def index(conn, _params) do
    escape_html_wat = WasmExamples.EscapeHTML.to_wat()
    html_page_wat = WasmExamples.HTMLPage.to_wat()
    counter_html_wat = WasmExamples.CounterHTML.to_wat()

    render(conn, :index,
      escape_html_wat: escape_html_wat,
      html_page_wat: html_page_wat,
      counter_html_wat: counter_html_wat,
      today: Date.utc_today()
    )
  end

  def module(conn, %{"module" => module}) do
    wat =
      case module do
        "escape_html.wasm" -> WasmExamples.EscapeHTML.to_wat()
        "html_page.wasm" -> WasmExamples.HTMLPage.to_wat()
        "counter_html.wasm" -> WasmExamples.CounterHTML.to_wat()
        "simple_weekday_parser.wasm" -> WasmExamples.SimpleWeekdayParser.to_wat()
      end

    wasm = ComponentsGuide.Wasm.WasmNative.wat2wasm(wat)
    # json(
    #   conn,
    #   WasmJSON.module(%{wat: wat})
    # )
    conn
    |> put_resp_content_type("application/wasm", nil)
    |> send_resp(200, wasm)
  end

  def script(conn, %{"script" => name}) do
    wasm_url =
      case name do
        # "escape_html.js" -> WasmExamples.EscapeHTML.to_wat()
        # "html_page.js" -> WasmExamples.HTMLPage.to_wat()
        # "counter_html.js" -> WasmExamples.CounterHTML.to_wat()
        "counter_html.js" -> "/wasm/module/counter_html.wasm"
        "simple_weekday_parser.js" -> "/wasm/module/simple_weekday_parser.wasm"
      end

    javascript = ~s"""
    export const wasmModulePromise = WebAssembly.compileStreaming(
      fetch("#{wasm_url}", {
        credentials: "omit"
      })
    );
    """

    conn
    |> put_resp_content_type("application/javascript")
    |> send_resp(200, javascript)
  end
end

defmodule ComponentsGuideWeb.WasmHTML do
  use ComponentsGuideWeb, :html

  alias ComponentsGuide.Wasm.WasmExamples.{CounterHTML}

  embed_templates("wasm_html/*")
end

defmodule ComponentsGuideWeb.WasmJSON do
  def module(assigns) do
    %{assigns: assigns}
  end
end
