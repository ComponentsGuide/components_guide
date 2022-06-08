defmodule ComponentsGuideWeb.ReactEditorController do
  use ComponentsGuideWeb, :controller

  def index(conn, _params) do
    source = ~s"""
import { flavors } from "https://gist.githubusercontent.com/BurntCaramel/d9d2ca7ed6f056632696709a2ae3c413/raw/0234322cf854d52e2f2bd33aa37e8c8b00f9df0a/1.js";
import reactDownloads from "https://api.npmjs.org/downloads/point/last-week/react";
import image from "https://embed.filekitcdn.com/e/fEiVX4E3EdQhij4RMaw92W/pziZhFNQLKJtwNHMTkDnTD";

const a = 1 + 1 + flavors.length;

function Inspect({ value }) {
  return <pre>{JSON.stringify(value, null, 2)}</pre>
}

function useTick() {
  return useReducer(n => n + 1, 0);
}

function useDebouncedTick(duration) {
  const [count, tick] = useTick();

  const callback = useMemo(() => {
    let timeout = null;
    function clear() {
      if (timeout) {
        clearTimeout(timeout);
        timeout = null;
      }
    }
    return () => {
      clear()
      timeout = setTimeout(tick, duration);
      return clear;
    };
  }, [duration, tick]);

  return [count, callback];
}

const decimalFormatter = new Intl.NumberFormat();
function Decimal({ children }) {
  return decimalFormatter.format(children);
}

export default function App() {
  const [count, tick] = useDebouncedTick(1000);
  return <>
    <div>Hello!! {flavors.join(" ")}</div>
    <button onClick={tick}>Click</button>
    <div>{count}</div>
    <div>React was downloaded <Decimal>{reactDownloads.downloads}</Decimal> times last week.</div>
    <img src={image} width={250} height={250} />
  </>;
}
"""

    render(conn, "index.html", source: source)
  end
end

defmodule ComponentsGuideWeb.ReactEditorView do
  use ComponentsGuideWeb, :view
end
