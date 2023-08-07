import { MemoryIO } from "../wasm/memoryIO";

class WasmSimpleHTML extends HTMLElement {
  connectedCallback() {
    const wasmURL = this.dataset.url ?? this.getAttribute("src") ?? this.querySelector("source[type='application/wasm']")?.src;
    if (!wasmURL) throw Error("Expected URL");

    // const wasmInstancePromise = WebAssembly.instantiateStreaming(fetch(wasmURL, { credentials: "omit" }), imports)
    //   .then(a => {
    //     console.log("Loaded wasm directly", Date.now() - window.startTime);
    //     return a;
    //   });
    const wasmModulePromise = WebAssembly.compileStreaming(fetch(wasmURL, { credentials: "omit" }))
      .then(a => {
        console.log("Loaded wasm directly", Date.now() - window.startTime);
        return a;
      });
    initWasmHTML(this, wasmModulePromise);
  }
}

async function initWasmHTML(el, wasmModulePromise) {
  const wasmModule = await wasmModulePromise;

  let memoryIO;
  const imports = {
    math: {
      powf32: (x, y) => Math.pow(x, y)
    },
    format: {
      f32: (f, memoryOffset) => {
        const s = String(f);
        return memoryIO.writeStringAt(s, memoryOffset);
      }
    },
    log: {
      i32: i => console.log("wasm", i),
      f32: f => console.log("wasm", f),
    }
  };
  const instance = await WebAssembly.instantiate(wasmModule, imports);
  
  memoryIO = new MemoryIO(instance.exports);
  const { to_html: toHTML } = instance.exports;

  function update() {
    const html = memoryIO.readString(toHTML());
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


  el.addEventListener("mousedown", (event) => {
    const action = event.target.closest("[data-action")?.dataset?.mousedown;
    console.log("ACTION", action, event.offsetX, event.offsetY);
    if (typeof action === "string") {
      instance.exports[action]?.apply();
      instance.exports["mousedown_offset"]?.apply(null, [event.offsetX, event.offsetY]);
    }
    update();
  });

  queueMicrotask(update);
}

customElements.define("wasm-simple-html", WasmSimpleHTML);
