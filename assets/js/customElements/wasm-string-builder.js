class WasmStringBuilder extends HTMLElement {
  connectedCallback() {
    const wasmURL = this.dataset.url ?? this.getAttribute("src") ?? this.querySelector("source[type='application/wasm']")?.src;
    if (wasmURL) {
      const wasmInstancePromise = WebAssembly.instantiateStreaming(fetch(wasmURL, { credentials: "omit" }))
      .then(a => {
        console.log("Loaded wasm directly", Date.now() - window.startTime);
        return a;
      });
      initWasmHTML(this, wasmInstancePromise);
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
          return instancePromise
            .then(instance => ({ instance, module }));
        });
      initWasmHTML(this, wasmInstancePromise);
    }
  }
}

const utf8encoder = new TextEncoder();
const utf8decoder = new TextDecoder();

function initWasmHTML(el, wasmInstancePromise) {
  const form = el.querySelector("form");
  const formElements = Array.from(form.elements);
  console.log(formElements);
  const slots = new Map(Array.from(el.querySelectorAll("[slot]"), slot => [slot.slot, slot]));
  
  wasmInstancePromise.then(({ instance, module: mod }) => {
    let updateCount = 0;
    
    async function update() {
      // const data = new Map(new FormData(form));
      // console.log(data)
      
      if (updateCount > 0) {
        // Reinstantiate instance from scratch.
        instance = await WebAssembly.instantiate(mod);
      }
      updateCount += 1;
      
      const { memory, to_string } = instance.exports;
      
      // for (const [name, value] of data) {
      //   instance.exports[name]?.apply();
      // }
      for (const formElement of formElements) {
        if (formElement.type === "checkbox" && formElement.checked) {
          instance.exports[formElement.name]?.apply();
        }
        
        if (formElement.type === "number") {
          instance.exports[formElement.name]?.call(null, formElement.valueAsNumber);
        }
      }
    
      const memoryBytes = new Uint8Array(memory.buffer);

      const ptr = to_string();
      if (ptr === 0) {
        return;
      }

      // Search for null-terminating byte.
      const endPtr = memoryBytes.indexOf(0, ptr);
      // Get subsection of memory between start and end, and decode it as UTF-8.
      const text = utf8decoder.decode(memoryBytes.subarray(ptr, endPtr));
      console.log("rendered text", text)
      slots.get("to_string").innerText = text;
    }

    el.addEventListener("change", (event) => {
      console.log("event", event);
      const { type, name } = event.target;
      console.log(type, name)
      if (type === "checkbox") {
        instance.exports[name]?.apply();
      }
      // const action = event.target.dataset.action;
      // if (typeof action === "string") {
      //   instance.exports[action]?.apply();
      // }
      update();
    });

    queueMicrotask(update);
  });
}

customElements.define("wasm-string-builder", WasmStringBuilder);
