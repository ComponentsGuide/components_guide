defmodule ComponentsGuideWeb.ReactEditorController do
  use ComponentsGuideWeb, :controller

  defp render_source(conn, source) do
    render(conn, "index.html", source: source, page_title: "React Playground")
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

  def show(conn, %{"id" => "useid"}) do
    source = ~s"""
    function Inner() {
      const id = useId()

      return <p>{id}</p>
    }

    const items = ["a", "b", "c"];

    export default function App() {
      const [counter, dispatch] = useReducer(n => n + 1, 0)

      return <nav class="prose">
        <button onClick={dispatch} className="px-3 border border-gray-700 rounded">Increment</button>
        <p>{counter}</p>
        <hr />
        No key:
        <Inner />
        <hr />
        Key of "a":
        <Inner key="a" />
        <hr />
        Key is counter state:
        <Inner key={counter} />
        <hr />
        <ul>
        {items.map(item => (
          <li key={item}><Inner /></li>
        ))}
        </ul>
      </nav>;
    }
    """

    render_source(conn, source)
  end

  def show(conn, %{"id" => "reducer-patterns"}) do
    source = ~s"""
    function OneWayExample() {
      const [isEnabled, enable] = useReducer(() => true, false);

      return <article class="flex items-center p-4 gap-2 bg-gray-200 rounded-lg">
        <output>{isEnabled ? 'Enabled' : 'Disabled'}</output>
        <button onClick={enable} className="px-3 py-1 text-white bg-black rounded-lg">One Way</button>
      </article>;
    }

    function ToggleExample() {
      const [on, toggle] = useReducer(flag => !flag, false);

      return <article class="flex items-center p-4 gap-2 bg-gray-200 rounded-lg">
        <output>{on ? 'On' : 'Off'}</output>
        <button onClick={toggle} className="px-3 py-1 text-white bg-black rounded-lg">Toggle</button>
      </article>;
    }

    function MenuBarExample() {
      const [openMenu, tap] = useReducer(
        (current, action) => {
          if (action === current) {
            return null; // Close if matches
          }

          return action; // Use passed value
        },
        null
      );

      const buttonClass = "p-2 bg-white";

      function renderButton(id, title) {
        const isOpen = id === openMenu;

        return <div className="relative">
          <button className={isOpen ? "px-3 py-2 text-white bg-blue-600" : "px-3 py-2 bg-white"} onClick={() => tap(id)}>{title}</button>
          {isOpen && <div className="absolute t-full bg-white w-32 h-12 shadow-xl opacity-80" />}
        </div>
      }

      return <article class="flex flex-col items-center p-4 gap-4 bg-gray-200 rounded-lg">
        <output>{JSON.stringify(openMenu)}</output>
        <section class="flex items-center px-4 bg-white">
          {renderButton("file", "File")}
          {renderButton("edit", "Edit")}
          {renderButton("view", "View")}
        </section>
      </article>;
    }

    export default function App() {
      return <div className="flex flex-col gap-2 items-center text-lg">
        <ToggleExample />
        <OneWayExample />
        <MenuBarExample />
      </div>;
    }
    """

    render_source(conn, source)
  end

  def show(conn, %{"id" => "yieldmachine"}) do
    source = ~s"""
    import { start, on } from "https://unpkg.com/yieldmachine@0.5.1/dist/yieldmachine.module.js"

    function SwitchMachine() {
      const { On, Off } = {
        *Off() {
          yield on("FLICK", On);
        },
        *On() {
          yield on("FLICK", Off);
        }
      };
      return Off;
    }

    function useMachine(machineDefinition) {
      const instance = useMemo(() => {
        const aborter = new AbortController();
        const machine = start(machineDefinition, { signal: aborter.signal });
        return {
          aborter, machine, dispatch: machine.next.bind(machine)
        };
      }, []);
      useEffect(() => {
        return () => {
          instance.aborter.abort();
        };
      });

      const state = useSyncExternalStore(
        (callback) => {
          instance.machine.eventTarget.addEventListener(
            "StateChanged",
            callback
          );
          return () => {
            instance.machine.eventTarget.removeEventListener(
              "StateChanged",
              callback
            );
          };
        },
        () => instance.machine.value,
        () => instance.machine.value
      );

      return Object.freeze([state, instance.dispatch]);
    }

    export default function App() {
      const [value, dispatch] = useMachine(SwitchMachine);

      return <article class="flex flex-col gap-2 items-center text-lg">
      <dl>
        <div className="flex gap-2">
          <dt className="font-bold">State:</dt>
          <dd>{value.state}</dd>
        </div>
        <div className="flex gap-2">
          <dt className="font-bold">Change</dt>
          <dd>{"#"}{value.change}</dd>
        </div>
      </dl>
        <button className="px-3 py-1 text-white bg-black rounded-lg" onClick={() => dispatch("FLICK")}>FLICK</button>
      </article>;
    }
    """

    render_source(conn, source)
  end

  def show(conn, %{"id" => "yieldmachine-gist"}) do
    source = ~s"""
    import { default as App } from "https://gist.githubusercontent.com/BurntCaramel/229db1ce87ea3126c460d232cc1e6b0c/raw/78bdd8c275de4bf38d5430bc0ee6bd6ca7014c84/traffic-lights.jsx";
    export default App;
    """

    render_source(conn, source)
  end

  def show(conn, %{"id" => "fetch"}) do
    source = ~s"""
    function fetchCloudFlareJSON() {
      return fetch("https://workers.cloudflare.com/cf.json").then(res => res.json());
    }

    function reducer(state, event) {
      if (event.type === "success") {
        return { data: event.data, t: event.t }
      } else if (event.type === "error") {
        return { error: event.error, t: event.t }
      } else {
        return state;
      }
    }

    function Result({ result }) {
      if (result === null) {
        return <p className="text-2xl">Idle</p>
      }

      if ("error" in result) {
        return <p className="text-2xl">Error! {result.error.message}</p>
      }

      const { country, colo, latitude, longitude } = result.data;

      return <div className="text-2xl">
        Loaded: {country} {colo} ({latitude}, {longitude})
        <details><summary>Raw data</summary>{JSON.stringify(result.data, null, 2)}</details></div>
    }

    export default function App() {
      const [state, dispatch] = useReducer(reducer, null);
      const [t, next] = useReducer(n => n + 1, 0);
      useEffect(() => {
        if (t === 0) return;

        fetchCloudFlareJSON()
          .then(data => {
            dispatch({ type: "success", data, t });
          })
          .catch(error => {
            dispatch({ type: "error", error, t });
          })
      }, [t]);

      return <div className="flex flex-col gap-2 items-center">
        <button onClick={next} className="px-3 py-1 text-xl text-white bg-black rounded-lg">Load</button>
        <Result result={state} />
      </div>;
    }
    """

    render_source(conn, source)
  end

  def show(conn, %{"id" => "headlessui"}) do
    source = ~s"""
    import { Menu } from "https://jspm.dev/@headlessui/react"

    export default function App() {
      return <nav class="prose">
        <Menu.Button>Hello</Menu.Button>
        <ul>
          <li><a href="/react-playground/react-elements" target="_blank">Understanding React Elements</a></li>
          <li><a href="/react-playground/useid" target="_blank">useId()</a></li>
          <li>
            <a href="/react-playground/lists" target="_blank">Rendering Lists</a>
            <ul>
              <li><a href="/react-playground/lists2" target="_blank">Optimization A</a></li>
              <li><a href="/react-playground/lists3" target="_blank">Optimization B</a></li>
            </ul>
          </li>
          <li><a href="/react-playground/fetch" target="_blank">Fetch</a></li>
          <li><a href="/react-playground/import-from-the-web" target="_blank">Importing from the Web</a></li>
        </ul>
      </nav>;
    }
    """

    render_source(conn, source)
  end

  def show(conn, %{"id" => "headlessui-tabs"}) do
    source = ~s"""
    import { Tab } from "https://jspm.dev/@headlessui/react"

    function classNames(...classes) {
      return classes.filter(Boolean).join(' ')
    }

    export default function App() {
      let [categories] = useState({
        Recent: [
          {
            id: 1,
            title: 'Does drinking coffee make you smarter?',
            date: '5h ago',
            commentCount: 5,
            shareCount: 2,
          },
          {
            id: 2,
            title: "So you've bought coffee... now what?",
            date: '2h ago',
            commentCount: 3,
            shareCount: 2,
          },
        ],
        Popular: [
          {
            id: 1,
            title: 'Is tech making coffee better or worse?',
            date: 'Jan 7',
            commentCount: 29,
            shareCount: 16,
          },
          {
            id: 2,
            title: 'The most innovative things happening in coffee',
            date: 'Mar 19',
            commentCount: 24,
            shareCount: 12,
          },
        ],
        Trending: [
          {
            id: 1,
            title: 'Ask Me Anything: 10 answers to your questions about coffee',
            date: '2d ago',
            commentCount: 9,
            shareCount: 5,
          },
          {
            id: 2,
            title: "The worst advice we've ever heard about coffee",
            date: '4d ago',
            commentCount: 1,
            shareCount: 2,
          },
        ],
      })

      return (
        <div className="flex justify-center bg-gradient-to-r from-sky-400 to-blue-600">
          <div className="w-full max-w-md px-2 py-16 sm:px-0">
            <Tab.Group>
              <Tab.List className="flex space-x-1 rounded-xl bg-blue-900/20 p-1">
                {Object.keys(categories).map((category) => (
                  <Tab
                    key={category}
                    className={({ selected }) =>
                      classNames(
                        'w-full rounded-lg py-2.5 text-sm font-medium leading-5 text-blue-700',
                        'ring-white ring-opacity-60 ring-offset-2 ring-offset-blue-400 focus:outline-none focus:ring-2',
                        selected
                          ? 'bg-white shadow'
                          : 'text-blue-100 hover:bg-white/[0.12] hover:text-white'
                      )
                    }
                  >
                    {category}
                  </Tab>
                ))}
              </Tab.List>
              <Tab.Panels className="mt-2">
                {Object.values(categories).map((posts, idx) => (
                  <Tab.Panel
                    key={idx}
                    className={classNames(
                      'rounded-xl bg-white p-3',
                      'ring-white ring-opacity-60 ring-offset-2 ring-offset-blue-400 focus:outline-none focus:ring-2'
                    )}
                  >
                    <ul>
                      {posts.map((post) => (
                        <li
                          key={post.id}
                          className="relative rounded-md p-3 hover:bg-gray-100"
                        >
                          <h3 className="text-sm font-medium leading-5">
                            {post.title}
                          </h3>

                          <ul className="mt-1 flex space-x-1 text-xs font-normal leading-4 text-gray-500">
                            <li>{post.date}</li>
                            <li>&middot;</li>
                            <li>{post.commentCount} comments</li>
                            <li>&middot;</li>
                            <li>{post.shareCount} shares</li>
                          </ul>

                          <a
                            href="#"
                            className={classNames(
                              'absolute inset-0 rounded-md',
                              'ring-blue-400 focus:z-10 focus:outline-none focus:ring-2'
                            )}
                          />
                        </li>
                      ))}
                    </ul>
                  </Tab.Panel>
                ))}
              </Tab.Panels>
            </Tab.Group>
          </div>
        </div>
      )
    }
    """

    render_source(conn, source)
  end

  def show(conn, %{"id" => "react-aria-useselect"}) do
    source = ~s"""
    import { HiddenSelect, useSelect } from 'https://jspm.dev/@react-aria/select';
    import { Item } from 'https://jspm.dev/@react-stately/collections';
    import { useButton } from 'https://jspm.dev/@react-aria/button';
    import { useSelectState } from 'https://jspm.dev/@react-stately/select';
    import { DismissButton, useOverlay } from 'https://jspm.dev/@react-aria/overlays';
    import { FocusScope } from 'https://jspm.dev/@react-aria/focus';
    import { useListBox, useOption } from 'https://jspm.dev/@react-aria/listbox';

    function ListBox(props) {
      let ref = React.useRef();
      let { listBoxRef = ref, state } = props;
      let { listBoxProps } = useListBox(props, state, listBoxRef);

      return (
        <ul
          {...listBoxProps}
          ref={listBoxRef}
          style={{
            margin: 0,
            padding: 0,
            listStyle: 'none',
            maxHeight: '150px',
            overflow: 'auto'
          }}
        >
          {[...state.collection].map((item) => (
            <Option
              key={item.key}
              item={item}
              state={state}
            />
          ))}
        </ul>
      );
    }

    function Option({ item, state }) {
      let ref = React.useRef();
      let { optionProps, isSelected, isFocused, isDisabled } = useOption(
        { key: item.key },
        state,
        ref
      );

      let backgroundColor;
      let color = 'black';

      if (isSelected) {
        backgroundColor = 'blueviolet';
        color = 'white';
      } else if (isFocused) {
        backgroundColor = 'gray';
      } else if (isDisabled) {
        backgroundColor = 'transparent';
        color = 'gray';
      }

      return (
        <li
          {...optionProps}
          ref={ref}
          style={{
            background: backgroundColor,
            color: color,
            padding: '2px 5px',
            outline: 'none',
            cursor: 'pointer'
          }}
        >
          {item.rendered}
        </li>
      );
    }

    function Popover(props) {
      let ref = React.useRef();
      let {
        popoverRef = ref,
        isOpen,
        onClose,
        children
      } = props;

      // Handle events that should cause the popup to close,
      // e.g. blur, clicking outside, or pressing the escape key.
      let { overlayProps } = useOverlay({
        isOpen,
        onClose,
        shouldCloseOnBlur: true,
        isDismissable: true
      }, popoverRef);

      // Add a hidden <DismissButton> component at the end of the popover
      // to allow screen reader users to dismiss the popup easily.
      return (
        <FocusScope restoreFocus>
          <div
            {...overlayProps}
            ref={popoverRef}
            style={{
              position: "absolute",
              width: "100%",
              border: "1px solid gray",
              background: "lightgray",
              marginTop: 4
            }}>
            {children}
            <DismissButton onDismiss={onClose} />
          </div>
        </FocusScope>
      );
    }

    function Select(props) {
      // Create state based on the incoming props
      let state = useSelectState(props);

      // Get props for child elements from useSelect
      let ref = React.useRef();
      let {
        labelProps,
        triggerProps,
        valueProps,
        menuProps
      } = useSelect(props, state, ref);

      // Get props for the button based on the trigger props from useSelect
      let { buttonProps } = useButton(triggerProps, ref);

      return (
        <div style={{ position: 'relative', display: 'inline-block' }}>
          <div {...labelProps}>{props.label}</div>
          <HiddenSelect
            state={state}
            triggerRef={ref}
            label={props.label}
            name={props.name}
          />
          <button
            {...buttonProps}
            ref={ref}
            style={{ height: 30, fontSize: 14 }}
          >
            <span {...valueProps}>
              {state.selectedItem
                ? state.selectedItem.rendered
                : 'Select an option'}
            </span>
            <span
              aria-hidden="true"
              style={{ paddingLeft: 5 }}
            >
              ▼
            </span>
          </button>
          {state.isOpen &&
            (
              <Popover isOpen={state.isOpen} onClose={state.close}>
                <ListBox
                  {...menuProps}
                  state={state}
                />
              </Popover>
            )}
        </div>
      );
    }

    export default function App() {
      return <main>
        <Select label="Favorite Color">
          <Item>Red</Item>
          <Item>Orange</Item>
          <Item>Yellow</Item>
          <Item>Green</Item>
          <Item>Blue</Item>
          <Item>Purple</Item>
          <Item>Black</Item>
          <Item>White</Item>
          <Item>Lime</Item>
          <Item>Fushsia</Item>
        </Select>
      </main>;
    }
    """

    render_source(conn, source)
  end

  def show(conn, %{"id" => "userecursive"}) do
    source = ~s"""
    function useRecursive(initial) {
      const [builder, dispatch] = useReducer((previous, value) => {
        return function*() {
          yield* previous();
          yield value;
        }
      }, function* () { yield initial })

      const values = useMemo(() => Array.from(builder()), [builder]);
      return [values, dispatch]
    }

    export default function App() {
      const [items, dispatch] = useRecursive("first")

      return <div>
        <button onClick={() => dispatch("New")}>New</button>
        <ul>{items.map((item, index) => <li key={index}>{item}</li>)}</ul>
      </div>
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
          <li><a href="/react-playground/useid" target="_blank">useId()</a></li>
          <li>
          <a href="/react-playground/lists" target="_blank">Rendering Lists</a>
            <ul>
              <li><a href="/react-playground/lists2" target="_blank">Optimization A</a></li>
              <li><a href="/react-playground/lists3" target="_blank">Optimization B</a></li>
            </ul>
          </li>
          <li><a href="/react-playground/fetch" target="_blank">Fetch</a></li>
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

  def skip_contentinfo, do: true
end
