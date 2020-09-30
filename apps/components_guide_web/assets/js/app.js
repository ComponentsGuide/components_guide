// We need to import the CSS so that webpack will load it.
// The MiniCssExtractPlugin is used to separate it out into
// its own CSS file.
import css from "../css/app.css";

// webpack automatically bundles all modules in your
// entry points. Those entry points can be configured
// in "webpack.config.js".
//
// Import dependencies
//
import "phoenix_html";
import { Socket } from "phoenix";
import NProgress from "nprogress";
import LiveSocket from "phoenix_live_view";

let csrfToken = document
  .querySelector("meta[name='csrf-token']")
  .getAttribute("content");
let liveSocket = new LiveSocket("/live", Socket, {
  params: { _csrf_token: csrfToken },
  hooks: {
    SwatchInput: {
      mounted() {
        const mouseEventHandler = (e) => {
          if (e.which !== 0) {
            const x = e.offsetX,
              y = e.offsetY;
            const maxX = this.el.width.baseVal.value;
            const maxY = this.el.height.baseVal.value;
            const xFraction = x / maxX;
            const yFraction = y / maxY;
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
window.addEventListener("phx:page-loading-start", info => NProgress.start());
window.addEventListener("phx:page-loading-stop", info => NProgress.done());

// connect if there are any LiveViews on the page
liveSocket.connect();

// expose liveSocket on window for web console debug logs and latency simulation:
// >> liveSocket.enableDebug()
// >> liveSocket.enableLatencySim(1000)
window.liveSocket = liveSocket;

import Vue from "vue";
