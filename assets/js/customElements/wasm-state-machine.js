class WasmStateMachine extends HTMLElement {
  connectedCallback() {
    const imports = { env: {} };

    const wasmURL = this.dataset.url;
    if (wasmURL) {
      const wasmInstancePromise = WebAssembly.instantiateStreaming(fetch(wasmURL, { credentials: "omit" }), imports)
      .then(a => {
        console.log("Loaded wasm directly", Date.now() - window.startTime);
        return a;
      });
      initWasmHTML(this, wasmInstancePromise);
    }

    if (this.dataset.scriptUrl) {
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
          const instancePromise = WebAssembly.instantiate(module, imports);
          return instancePromise;
        })
        .then(instance => ({ instance }));
      initWasmHTML(this, wasmInstancePromise);
    }
  }
}

function initWasmHTML(el, wasmInstancePromise) {
  wasmInstancePromise.then(({ instance }) => {
    const buttonTemplate = el.querySelector("[data-template=button]").content;

    const globalNames = Object.keys(instance.exports).filter(name => instance.exports[name] instanceof WebAssembly.Global);
    const globalMap = new Map(
      Array.from(globalNames, globalName => [globalName, instance.exports[globalName]]).concat(
        Array.from(globalNames, globalName => [instance.exports[globalName].value, globalName])
      )
    );
    const functionNames = Object.keys(instance.exports)
    .filter(name => typeof instance.exports[name] === "function");
    const eventNames = functionNames.filter(name => !name.startsWith("get_") && !name.endsWith("?"));
    const calculationNames = functionNames.filter(name => name.endsWith("?") || name.startsWith("get_"));

    function getCurrentText() {
      const current = instance.exports.get_current();
      return String(globalMap.get(current) ?? current);
    }

    function update() {
      const slots = new Map(Array.from(el.querySelectorAll("[slot]"), slot => [slot.slot, slot]))
      
      const eventHandlersEl = slots.get("eventHandlers");
      eventHandlersEl.innerHTML = "";
      for (eventName of eventNames) {
        const eventEl = buttonTemplate.cloneNode(true);
        const buttonEl = eventEl.querySelector("button");
        buttonEl.textContent = eventName;
        buttonEl.dataset.action = eventName;
        eventHandlersEl.appendChild(eventEl);
      }

      for (globalName of globalNames) {
        const slot = slots.get(globalName);
        if (slot) {
          slot.textContent = `${globalName} = ${instance.exports[globalName].value}`;
        }
      }

      for (calculationName of calculationNames) {
        const slot = slots.get(calculationName);
        if (slot) {
          slot.textContent = `${calculationName}: ${instance.exports[calculationName]()}`;
        }
      }

      if (slots.get("globalsList")?.childElementCount === 0) {
        const listEl = slots.get("globalsList");
        for (globalName of globalNames) {
          listEl.appendChild(Object.assign(el.ownerDocument.createElement("li"), {
            textContent: `${globalName} = ${instance.exports[globalName].value}`
          }));
        }
      }

      if (slots.has("state") && typeof instance.exports["get_current"] === "function") {
        slots.get("state").textContent = getCurrentText();
      }
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

customElements.define("wasm-state-machine", WasmStateMachine);
