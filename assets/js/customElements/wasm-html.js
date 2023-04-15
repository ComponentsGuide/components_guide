class WasmHTML extends HTMLElement {
  connectedCallback() {
    const wasmURL = this.dataset.url;
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

    if (this.dataset.scriptUrl) {
      const memory = new WebAssembly.Memory({ initial: 2 });
      const wasmModulePromise = window.importModule(this.dataset.scriptUrl);
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
      initWasmHTML(this, wasmInstancePromise, memory);
    }
  }
}

function initWasmHTML(el, wasmInstancePromise, memory) {
  wasmInstancePromise.then(({ instance }) => {
    const rewind = instance.exports.rewind;
    const next_body_chunk = instance.exports.next_body_chunk;

    const memoryBytes = new Uint8Array(memory.buffer);
    //const memoryToWrite = memoryBytes.subarray(1024);
    //const memoryToRead = memoryBytes.subarray(2048);
    const utf8encoder = new TextEncoder();
    const utf8decoder = new TextDecoder();

    function update() {
      rewind();

      const chunks = [];
      //const chunks = new Uint8Array(1000);
      while (true) {
        const ptr = next_body_chunk();
        if (ptr === 0) {
          break;
        }

        // Search for null-terminating byte.
        const endPtr = memoryBytes.indexOf(0, ptr);
        // Get subsection of memory between start and end, and decode it as UTF-8.
        //return utf8decoder.decode(memoryBytes.subarray(ptr, endPtr));
        //chunks.concat(memoryToRead.subarray(0, count));
        chunks.push(memoryBytes.subarray(ptr, endPtr));
        //chunks.set(memoryBytes.subarray(ptr, endPtr), chunks.length);
      }

      // There surely must be a better way to do this.
      // See: https://stackoverflow.com/questions/49129643/how-do-i-merge-an-array-of-uint8arrays
      const bytes = new Uint8Array(chunks.map(chunk => [...chunk]).flat());
      const html = utf8decoder.decode(bytes);
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
  });
}

customElements.define("wasm-html", WasmHTML);
