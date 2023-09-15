import { MemoryIO } from "../wasm/memoryIO";

class WasmChunkedHTML extends HTMLElement {
  connectedCallback() {
    console.log("WASM CONNECTED", this)
    const wasmURL = this.dataset.url ?? this.getAttribute("src") ?? this.querySelector("source[type='application/wasm']")?.src;
    if (wasmURL) {
      const memory = new WebAssembly.Memory({ initial: 2 });
      const wasmInstancePromise = WebAssembly.instantiateStreaming(fetch(wasmURL, { credentials: "omit" }), {
        env: {
          buffer: memory
        }
      })
        .then(a => {
          console.log("Loaded wasm directly", Date.now() - window.startTime);
          return a;
        });
      initWasmHTML(this, wasmInstancePromise, memory);
    }

    const importUrl = this.dataset.importUrl ?? this.querySelector("source[type='text/javascript']")?.src;
    if (importUrl) {
      const memory = new WebAssembly.Memory({ initial: 2 });
      const wasmModulePromise = window.importModule(importUrl);
      console.log("import(this.dataset.scriptUrl)", wasmModulePromise);
      const wasmInstancePromise = wasmModulePromise
        .then(exports => {
          console.log("Loaded wasm via import()", Date.now() - window.startTime);
          console.log("ES MODULE", exports);
          return exports.wasmModulePromise;
        })
        .then(module => {
          console.log("MODULE", module);
          const instancePromise = WebAssembly.instantiate(module, {
            env: {
              buffer: memory
            }
          });
          return instancePromise;
        })
        .then(instance => ({ instance }));
      initWasmHTML(this, wasmInstancePromise);
    }
  }
}

async function initWasmHTML(el, wasmInstancePromise) {
  const { instance } = await wasmInstancePromise;
  const rewind = instance.exports.rewind;
  const next_body_chunk = instance.exports.next_body_chunk;

  const memoryIO = new MemoryIO(instance.exports);

  function update() {
    rewind?.call();

    const stringChunks = [];
    while (true) {
      const ptr = next_body_chunk();
      if (ptr === 0) {
        break;
      }

      stringChunks.push(memoryIO.readString(ptr));
    }

    const html = stringChunks.join("");
    console.log("wasm-html render", html)
    el.innerHTML = html;
  }

  el.addEventListener("click", (event) => {
    const action = event.target.dataset.action;
    if (typeof action === "string") {
      instance.exports[action]?.apply();
    }
    update();
  });

  queueMicrotask(update);
}

customElements.define("wasm-chunked-html", WasmChunkedHTML);
