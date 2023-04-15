defmodule ComponentsGuideWeb.WasmShared do
  defmacro all_modules do
    Macro.escape(%{
      "escape_html.wasm" => WasmExamples.EscapeHTML,
      "html_page.wasm" => WasmExamples.HTMLPage,
      "counter_html.wasm" => WasmExamples.CounterHTML,
      "simple_weekday_parser.wasm" => WasmExamples.SimpleWeekdayParser,
      "sitemap_builder.wasm" => WasmExamples.SitemapBuilder
    })
  end
end

defmodule ComponentsGuideWeb.WasmController do
  use ComponentsGuideWeb, :controller
  plug :put_view, html: ComponentsGuideWeb.WasmHTML, json: ComponentsGuideWeb.WasmJSON
  alias ComponentsGuide.Wasm.WasmExamples

  @modules %{
    "escape_html.wasm" => WasmExamples.EscapeHTML,
    "html_page.wasm" => WasmExamples.HTMLPage,
    "counter_html.wasm" => WasmExamples.CounterHTML,
    "simple_weekday_parser.wasm" => WasmExamples.SimpleWeekdayParser
  }

  def index(conn, _params) do
    assigns =
      case get_format(conn) do
        "html" ->
          [
            escape_html_wat: WasmExamples.EscapeHTML.to_wat(),
            html_page_wat: WasmExamples.HTMLPage.to_wat(),
            counter_html_wat: WasmExamples.CounterHTML.to_wat()
          ]

        _ ->
          []
      end

    render(conn, :index, assigns)
  end

  def module(conn, %{"module" => name}) when is_map_key(@modules, name) do
    wasm = @modules[name].to_wasm()
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
  require ComponentsGuideWeb.WasmShared
  @modules ComponentsGuideWeb.WasmShared.all_modules()

  def index(_assigns) do
    # paths =
    #   ["escape_html", "html_page", "counter_html", "simple_weekday_parser", "sitemap_builder"]
    #   |> Enum.map(fn name -> "/wasm/module/#{name}.wasm" end)

    paths = @modules |> Enum.map(fn {name, _} -> "/wasm/module/#{name}" end)

    %{paths: paths}
  end

  def module(assigns) do
    %{assigns: assigns}
  end
end
