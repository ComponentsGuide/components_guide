defmodule ComponentsGuideWeb.ReactEditorController do
  use ComponentsGuideWeb, :controller

  defp render_source(conn, source) do
    render(conn, "index.html", source: source)
  end

  def show(conn, %{"id" => "react-elements"}) do
    source = ~S"""
    export default function App() {
      return <div className="flex flex-col gap-2 items-center">
        <Inspect value={<pre />} />
        <Inspect value={<button type="submit" />} />
        <Inspect value={<button key="hello" type="submit" onClick={() => {}} />} />
        <Inspect value={<React.Fragment />} />
        <Inspect value={<React.Suspense />} />
        <Inspect value={React.lazy()} />
      </div>;
    }

    function Inspect({ value }) {
      const inspected = Array.from(inspectObject(value)).join("");
      return <div className="prose"><pre>{inspected}</pre></div>;
    }

    function* inspectObject(object, outerIndent = '') {
      yield '{\\n';
      const indent = outerIndent + '  ';
      const keys = Object.keys(object);
      for (const prop of keys) {
        if (object.hasOwnProperty(prop)) {
          const value = object[prop];
          if (typeof value === 'undefined') {
            yield indent + prop + ": undefined";
          }
          if (typeof value === 'string' || typeof value === 'number') {
            yield indent + prop + ": " + JSON.stringify(value);
          }
          if (typeof value === 'symbol') {
            if (Symbol.keyFor(value)) {
              yield indent + prop + ": Symbol.for(" + value.description + ")";
            } else {
              yield indent + prop + ": " + value.toString();
            }
          }
          if (typeof value === 'function') {
            yield indent + prop + ": " + value.toString();
          }
          if (typeof value === 'object') {
            if (value === null) {
              yield indent + prop + ": null";
            } else {
              yield indent + prop + ": ";
              yield* inspectObject(value, indent);
            }
          }
          yield ",\\n"
        }
      }
      yield outerIndent + '}';
    }
    """

    render_source(conn, source)
  end

  def show(conn, %{"id" => "lists"}) do
    source = ~s"""
    const INITIAL_COUNT = 1000;
    const initialItems = Array.from({ length: INITIAL_COUNT }, (_, i) => ({ id: i }));

    function Item({ item, onFlip }) {
      return <li><button onClick={onFlip}>{item.id}</button></li>
    }

    export default function App() {
      const [items, updateItems] = useState(initialItems);

      function addItem() {
        updateItems(items => items.concat({ id: Math.random() }))
      }
      function flipItem(id) {
        updateItems(items => items.map(item => item.id === id ? ({ id: -item.id }) : item))
      }

      return <div className="flex flex-col gap-2 items-center">
        <button onClick={addItem} className ="px-3 py-1 text-xl text-white bg-black rounded-lg">Add Item</button>
        <ul className="text-center text-2xl">
          {items.map(item => <Item key={item.id} item={item} onFlip={() => flipItem(item.id)} />)}
        </ul>
      </div>;
    }
    """

    render_source(conn, source)
  end

  def show(conn, %{"id" => "lists2"}) do
    source = ~s"""
    const INITIAL_COUNT = 1000;
    const initialItems = Array.from({ length: INITIAL_COUNT }, (_, i) => ({ id: i }));

    const Item = React.memo(function Item({ item, onFlip }) {
      return <li><button onClick={() => onFlip(item.id)}>{item.id}</button></li>
    })

    export default function App() {
      const [items, updateItems] = useState(initialItems);

      const { addItem, flipItem } = useMemo(() => {
        function addItem() {
          updateItems(items => items.concat({ id: Math.random() }))
        }
        function flipItem(id) {
          updateItems(items => items.map(item => item.id === id ? ({ id: -item.id }) : item))
        }
        return {addItem, flipItem}
      }, [updateItems]);

      return <div className="flex flex-col gap-2 items-center">
        <button onClick={addItem} className ="px-3 py-1 text-xl text-white bg-black rounded-lg">Add Item</button>
        <ul className="text-center text-2xl">
          {items.map(item => <Item key={item.id} item={item} onFlip={flipItem} />)}
        </ul>
      </div>;
    }
    """

    render_source(conn, source)
  end

  def show(conn, %{"id" => "lists3"}) do
    source = ~s"""
    const INITIAL_COUNT = 1000;
    const initialItems = Array.from({ length: INITIAL_COUNT }, (_, i) => ({ id: i }));

    const Item = React.memo(function Item({ item }) {
      return <li data-item-id={item.id}><button>{item.id}</button></li>
    })

    export default function App() {
      const [items, updateItems] = useState(initialItems);

      function addItem() {
        updateItems(items => items.concat({ id: Math.random() }))
      }
      function flipItem(event) {
        const id = event.target.closest('[data-item-id]').dataset['itemId'];
        console.log("id", id)
        updateItems(items => items.map(item => String(item.id) === id ? ({ id: -item.id }) : item))
      }

      return <div className="flex flex-col gap-2 items-center">
        <button onClick={addItem} className ="px-3 py-1 text-xl text-white bg-black rounded-lg">Add Item</button>
        <ul className="text-center text-2xl" onClick={flipItem}>
          {items.map(item => <Item key={item.id} item={item} />)}
        </ul>
      </div>;
    }

    """

    render_source(conn, source)
  end

  def show(conn, %{"id" => "import-from-the-web"}) do
    source = ~s"""
    import { flavors } from "https://gist.githubusercontent.com/BurntCaramel/d9d2ca7ed6f056632696709a2ae3c413/raw/0234322cf854d52e2f2bd33aa37e8c8b00f9df0a/1.js";
    import reactDownloads from "https://api.npmjs.org/downloads/point/last-week/react";
    import image from "https://embed.filekitcdn.com/e/fEiVX4E3EdQhij4RMaw92W/pziZhFNQLKJtwNHMTkDnTD";

    const a = 1 + 1 + flavors.length;

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

    render_source(conn, source)
  end

  def show(conn, params) do
    source = ~s"""
    export default function App() {
    const [count, next] = useReducer(n => n + 1, 0);
    return <div className="flex flex-col gap-2 items-center">
      <div className="text-2xl">{count}</div>
      <button onClick={next} className="px-3 py-1 text-xl text-white bg-black rounded-lg">Increment</button>
    </div>;
    }
    """

    render_source(conn, source)
  end

  def index(conn, _params) do
    source = ~s"""
    export default function App() {
      return <nav class="prose">
        <ul>
          <li><a href="/react-playground/react-elements" target="_blank">Understanding React Elements</a></li>
          <li>
          <a href="/react-playground/lists" target="_blank">Rendering Lists</a>
            <ul>
              <li><a href="/react-playground/lists2" target="_blank">Optimization A</a></li>
              <li><a href="/react-playground/lists3" target="_blank">Optimization B</a></li>
            </ul>
          </li>
          <li><a href="/react-playground/import-from-the-web" target="_blank">Importing from the Web</a></li>
        </ul>
      </nav>;
    }
    """

    render_source(conn, source)
  end
end

defmodule ComponentsGuideWeb.ReactEditorView do
  use ComponentsGuideWeb, :view
end
