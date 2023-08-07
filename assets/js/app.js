// webpack automatically bundles all modules in your
// entry points. Those entry points can be configured
// in "webpack.config.js".
//
// Import dependencies
//
import "phoenix_html";
import { Socket } from "phoenix";
import { LiveSocket } from "phoenix_live_view";
import topbar from "../vendor/topbar";

import "./customElements/enhanced-navigation";
import "./customElements/wasm-simple-html";
import "./customElements/wasm-html";
import "./customElements/wasm-state-machine";
import "./customElements/wasm-string-builder";
import "./customElements/wasm-http-server";

window.IMPORT = {
  DOMTesting: () => import("@testing-library/dom")
};

let csrfToken = document
  .querySelector("meta[name='csrf-token']")
  .getAttribute("content");
let liveSocket = new LiveSocket("/live", Socket, {
  params: { _csrf_token: csrfToken },
  hooks: {
    PreCode: {
      mounted() {
        this._highlight();
      },
      updated() {
        this._highlight();
      },
      _highlight() {
        window.Prism.highlightElement(this.el);
      },
    },
    SwatchInput: {
      mounted() {
        const mouseEventHandler = (e) => {
          if (e.buttons === 1) {
            const x = e.offsetX,
              y = e.offsetY;
            const maxX = this.el.width.baseVal.value;
            const maxY = this.el.height.baseVal.value;
            const xFraction = x / maxX;
            const yFraction = y / maxY;
            console.log({maxX, maxY, xFraction})
            const value = (xFraction + yFraction) / 2;
            const { colorProperty } = this.el.dataset;
            this.pushEvent("color_property_changed", { [colorProperty]: `${value}` });
          }
        }
        this.el.addEventListener("mousedown", mouseEventHandler);
        this.el.addEventListener("mousemove", mouseEventHandler);
      }
    }
  }
});

// Show progress bar on live navigation and form submits
topbar.config({ barColors: { 0: "#29d" }, shadowColor: "rgba(0, 0, 0, .3)" })
window.addEventListener("phx:page-loading-start", info => topbar.show())
window.addEventListener("phx:page-loading-stop", info => topbar.hide())

// connect if there are any LiveViews on the page
liveSocket.connect();

// expose liveSocket on window for web console debug logs and latency simulation:
// >> liveSocket.enableDebug()
// >> liveSocket.enableLatencySim(1000)
window.liveSocket = liveSocket;

window.customElements.define('loading-stopwatch', class extends HTMLElement {
  connectedCallback() {
    const start = Date.now();
    this.interval = setInterval(() => {
      const duration = ((Date.now() - start) / 1000).toFixed(1);
      this.innerText = `${duration}s`;
    }, 100);
  }

  disconnectedCallback() {
    if (this.interval) {
      clearInterval(this.interval);
      this.interval = undefined;
    }
  }
});

