defmodule ComponentsGuideWeb.WasmShared do
  alias ComponentsGuide.Wasm.Examples
  alias ComponentsGuide.Wasm.Examples.Numeric
  alias ComponentsGuide.Wasm.Examples.HTML
  alias ComponentsGuide.Wasm.Examples.SVG
  alias ComponentsGuide.Wasm.Examples.State
  alias ComponentsGuide.Wasm.Examples.HTTPHeaders

  @all_modules %{
    "escape_html.wasm" => HTML.EscapeHTML,
    "html_page.wasm" => HTML.HTMLPage,
    "counter_html.wasm" => HTML.CounterHTML,
    "svg_square.wasm" => SVG.Square,
    "simple_weekday_parser.wasm" => Examples.SimpleWeekdayParser,
    "sitemap_builder.wasm" => Examples.SitemapBuilder,
    "numeric_unit_interval.wasm" => Numeric.UnitInterval,
    "offline_status.wasm" => State.OfflineStatus,
    "dialog_state.wasm" => State.Dialog,
    "promise_state.wasm" => State.Promise,
    "form_state_machine.wasm" => State.Form,
    "http_header_cache_control.wasm" => HTTPHeaders.CacheControl,
    "http_header_set_cookie.wasm" => HTTPHeaders.SetCookie
  }

  defmacro all_modules(), do: Macro.escape(@all_modules)
end

defmodule ComponentsGuideWeb.WasmController do
  use ComponentsGuideWeb, :controller
  plug(:put_view, html: ComponentsGuideWeb.WasmHTML, json: ComponentsGuideWeb.WasmJSON)

  alias ComponentsGuide.Wasm.Examples.HTML
  alias ComponentsGuide.Wasm.Examples.State

  import ComponentsGuideWeb.WasmShared
  @modules all_modules()

  def index(conn, _params) do
    assigns =
      case get_format(conn) do
        "html" ->
          [
            escape_html_wat: HTML.EscapeHTML.to_wat(),
            html_page_wat: HTML.HTMLPage.to_wat(),
            counter_html_wat: HTML.CounterHTML.to_wat(),
            offline_status_wat: State.OfflineStatus.to_wat(),
            dialog_state_wat: State.Dialog.to_wat(),
            promise_state_wat: State.Promise.to_wat(),
            form_state_wat: State.Form.to_wat()
          ]

        _ ->
          []
      end

    render(conn, :index, assigns)
  end

  def module(conn, %{"module" => name}) when is_map_key(@modules, name) do
    wasm = @modules[name].to_wasm()

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

  alias ComponentsGuide.Wasm.Examples.HTML.{CounterHTML}

  embed_templates("wasm_html/*")

  import ComponentsGuideWeb.WasmShared
  @modules all_modules()

  def wat_module_source(name) when is_map_key(@modules, name) do
    @modules[name].to_wat()
  end

  def blue_button(assigns) do
    ~H"""
    <button
      type={assigns[:type]}
      class={[
        "mt-4 px-3 py-1 text-blue-100 bg-blue-600 hover:text-blue-800 hover:bg-blue-300 border border-blue-500 rounded-lg",
        assigns[:class]
      ]}
      {assigns[:rest] || []}
    >
      <%= render_slot(@inner_block) %>
    </button>
    """
  end
end

defmodule ComponentsGuideWeb.WasmJSON do
  import ComponentsGuideWeb.WasmShared
  @modules all_modules()

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
