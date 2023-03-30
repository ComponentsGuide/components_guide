defmodule ComponentsGuideWeb.WasmController do
  use ComponentsGuideWeb, :controller
  # plug :put_view, html: ComponentsGuideWeb.WasmHTML, json: ComponentsGuideWeb.WasmJSON
  alias ComponentsGuide.Rustler.Wasm
  alias ComponentsGuide.Wasm.WasmExamples

  def index(conn, _params) do
    escape_html_wat = WasmExamples.EscapeHTML.to_wat()

    render(conn, :index,
      escape_html_wat: escape_html_wat,
      today: Date.utc_today()
    )
  end

  def module(conn, %{"module" => module}) do
    wat =
      case module do
        "escape_html.wasm" -> WasmExamples.EscapeHTML.to_wat()
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

  def index(assigns) do
    ~H"""
    <article class="text-white max-w-4xl mx-auto px-4 py-16">
      <custom-interactivity data-url="/wasm/module/escape_html.wasm">
        <form id="multiply-form">
          <label for="input-a">
            Input to be HTML escaped
            <textarea id="input-a" name="input" rows="8" class="block w-full text-black"><%= "Milo & Otis" %></textarea>
          </label>
          <button hidden>Run</button>
          <h3 class="mt-4">Resulting HTML:</h3>
          <output style="display: block; margin-top: 1rem;" class="font-mono"></output>
        </form>
      </custom-interactivity>
      <details class="mt-8">
        <summary>View Wasm source</summary>
        <pre><%= @escape_html_wat %></pre>
      </details>
    </article>

    <script type="module">
      class CustomInteractivity extends HTMLElement {
        constructor() {
          super();

          const wasmURL = this.dataset.url;
          init(wasmURL);
        }
      }

      function init(wasmURL) {
        const form = document.querySelector('form#multiply-form');
        const output = form.querySelector("output");

        const memory = new WebAssembly.Memory({ initial: 2 });
        const wasmPromise = WebAssembly.instantiateStreaming(fetch(wasmURL), {
          env: {
            buffer: memory
          }
        });
        wasmPromise.then(({ instance, module }) => {
          const escape_html = instance.exports.escape_html;
          output.innerText = "Change to see the calculation live locally.";

          const memoryBytes = new Uint8Array(memory.buffer);
          const memoryToWrite = memoryBytes.subarray(1024);
          const memoryToRead = memoryBytes.subarray(2048);
          //memory.set();
          const utf8encoder = new TextEncoder();
          const utf8decoder = new TextDecoder();

          function update() {
            const data = new FormData(form);
            const input = String(data.get("input"));
            const { written } = utf8encoder.encodeInto(input, memoryToWrite);
            const count = escape_html();
            memoryToWrite.fill(0, 0, written);
            //const text = utf8decoder.decode(memoryBytes.subarray(2048, 2048 + count));
            const text = utf8decoder.decode(memoryToRead.subarray(0, count));
            output.innerText = `${count} ${text}`;
            console.log(count);
          }

          form.addEventListener("input", (event) => {
            //event.preventDefault();
            update();
          });
          requestAnimationFrame(update);
        });
      }

      customElements.define("custom-interactivity", CustomInteractivity);
    </script>
    """
  end

  # embed_templates("wasm_html/*")
end

defmodule ComponentsGuideWeb.WasmJSON do
  def module(assigns) do
    %{assigns: assigns}
  end
end
