# WebAssembly Custom Elements

Extend HTML with Custom HTML Elements, and make them interactive with JavaScript.

## `<wasm-html>`

The element lets you use a WebAssembly instance that renders HTML. It loads your WebAssembly module for you, and instantiates it hooking into your exports. It expects specific exports:

- a `memory` exported under the name `"memory"`, which it will read the HTML text from (using the `MemoryIO` helper class below).
- a `to_html()` function that returns the memory offset to your built HTML. This will be called on each render.
- an optional `free_all()` function that is called at the start of each render, used to free memory if you need.

If your rendered HTML includes a `<button>` with a `data-action` attribute, then a click listener will be added. The value of this attribute if set to the name of an exported function, will be called every time the button is clicked. The HTML will also be re-rendered for you.

For example a `<button data-action="increment">Increment counter</button>` will call the `increment()` function you export, plus call your `to_html()` function, allowing you to re-render say a counter from `<output>1</output>` to `<output>2</output>`. Note: you must render the button each time: this allow you to change which buttons are available depending on your internal state.

### Usage

```html
<wasm-html class="block">
  <source src="url/to/your/module.wasm" type="application/wasm" />
</wasm-html>
```

### Source

```js
class WasmHTML extends HTMLElement {
  connectedCallback() {
    const wasmURL =
      this.getAttribute("src") ??
      this.querySelector("source[type='application/wasm']")?.src;
    if (!wasmURL) throw Error("Expected wasm URL as 'src' attribute or child <source>");

    const wasmModulePromise = WebAssembly.compileStreaming(
      fetch(wasmURL, { credentials: "omit" });
    initWasmHTML(this, wasmModulePromise);
  }
}

async function initWasmHTML(el, wasmModulePromise) {
  const wasmModule = await wasmModulePromise;

  let memoryIO;
  const imports = {
    math: {
      powf32: (x, y) => Math.pow(x, y),
    },
    format: {
      f32: (f, memoryOffset) => {
        let s = String(f);
        // We always want a `.0` suffix, even for integers.
        if (!/[.]/.test(s)) {
          s = f.toFixed(1);
        }
        return memoryIO.writeStringAt(s, memoryOffset);
      },
    },
    log: {
      i32: (i) => console.log("wasm", i),
      f32: (f) => console.log("wasm", f),
    },
  };
  const instance = await WebAssembly.instantiate(wasmModule, imports);

  memoryIO = new MemoryIO(instance.exports);
  const { to_html: toHTML, free_all: freeAll } = instance.exports;

  function update() {
    freeAll?.apply();
    const html = memoryIO.readString(toHTML());
    el.innerHTML = html;
  }

  // See definition below.
  addEventListenersToWasmInstance(instance, update);

  // Schedule initial update.
  queueMicrotask(update);
}

customElements.define("wasm-html", WasmHTML);
```

## Event listeners

```js
function addEventListenersToWasmInstance(instance, update) {
  el.addEventListener("click", (event) => {
    const action = event.target.dataset.action;
    if (typeof action === "string") {
      instance.exports[action]?.apply();
      update();
    }
  });

  el.addEventListener("pointerdown", (event) => {
    if (event.buttons === 1) {
      const actionTarget = event.target.closest("[data-action");
      if (actionTarget == null) return;

      const action = actionTarget.dataset.pointerdown;
      if (typeof action === "string") {
        instance.exports[action]?.apply();
        instance.exports["pointerdown_offset"]?.apply(null, [
          event.offsetX,
          event.offsetY,
        ]);
        update();
      }
    }
  });

  el.addEventListener("pointermove", (event) => {
    if (event.buttons === 1) {
      const actionTarget = event.target.closest("[data-action");
      if (actionTarget == null) return;

      const action = actionTarget.dataset["pointerdown+pointermove"];
      if (typeof action === "string") {
        // instance.exports[action]?.apply();
        instance.exports["pointermove_offset"]?.apply(null, [
          event.offsetX,
          event.offsetY,
        ]);
        update();
      }
    }
  });
}
```

## MemoryIO

```js
const utf8Encoder = new TextEncoder();
const utf8Decoder = new TextDecoder();

export class MemoryIO {
  constructor(exports) {
    this.memoryBytes = new Uint8Array(exports.memory.buffer);
    this.alloc = exports.alloc;
  }

  readString(ptr) {
    const { memoryBytes } = this;

    // Search for null-terminating byte.
    const endPtr = memoryBytes.indexOf(0, ptr);
    // Get subsection of memory between start and end, and decode it as UTF-8.
    return utf8Decoder.decode(memoryBytes.subarray(ptr, endPtr));
  }

  writeStringAt(stringValue, memoryOffset) {
    const { memoryBytes } = this;

    stringValue = stringValue.toString();
    const bytes = utf8Encoder.encode(stringValue);
    utf8Encoder.encodeInto(stringValue, memoryBytes.subarray(memoryOffset));
    memoryBytes[memoryOffset + bytes.length] = 0x0;
    return bytes.byteLength;
  }

  writeString(stringValue) {
    const { memoryBytes, alloc } = this;

    stringValue = stringValue.toString();
    const bytes = utf8Encoder.encode(stringValue);
    const strPtr = alloc(bytes.length + 1);
    utf8Encoder.encodeInto(stringValue, memoryBytes.subarray(strPtr));
    memoryBytes[strPtr + bytes.length] = 0x0;
    return Object.freeze([strPtr, bytes.byteLength]);
  }
}
```
