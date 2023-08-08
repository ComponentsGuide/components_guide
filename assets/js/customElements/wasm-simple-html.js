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
        let s = String(f);
        // We always want a `.0` suffix, even for integers.
        if (!/[.]/.test(s)) {
          s = f.toFixed(1);
        }
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
  const { to_html: toHTML, free_all } = instance.exports;

  function update() {
    free_all?.apply();
    const html = memoryIO.readString(toHTML());
    el.innerHTML = html;
  }

  el.addEventListener("click", (event) => {
    const action = event.target.dataset.action;
    if (typeof action === "string") {
      instance.exports[action]?.apply();
      update();
    }
  });

  el.addEventListener("mousedown", (event) => {
    if (event.buttons === 1) {
      const action = event.target.closest("[data-action")?.dataset?.mousedown;
      if (typeof action === "string") {
        instance.exports[action]?.apply();
        instance.exports["mousedown_offset"]?.apply(null, [event.offsetX, event.offsetY]);
        update();
      }
    }
  });

  el.addEventListener("mousemove", (event) => {
    if (event.buttons === 1) {
      const action = event.target.closest("[data-action")?.dataset?.mousedownMousemove;
      if (typeof action === "string") {
        instance.exports[action]?.apply();
        instance.exports["mousemove_offset"]?.apply(null, [event.offsetX, event.offsetY]);
        update();
      }
    }
  });

  queueMicrotask(update);
}

customElements.define("wasm-simple-html", WasmSimpleHTML);
