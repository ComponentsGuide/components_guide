defmodule ComponentsGuideWeb.ReactEditorController do
  use ComponentsGuideWeb, :controller_view

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

  def show(conn, %{"id" => "form-reducer-validation"}) do
    source = ~s"""
    function formDataFrom(element) {
      if (element instanceof HTMLFormElement) {
        return new FormData(element);
      }

      const formData = new FormData();
      if (element instanceof HTMLInputElement) {
        formData.set(element.name, element.value);
      }
      return formData;
    }

    function reducer(state, event) {
      if (event.type === "submit") {
        event.preventDefault();
      }

      const errors = new Map(state.errors);
      for (const [name, value] of formDataFrom(event.target)) {
        errors.delete(name);

        // TODO: add more advanced validation here
        if (value.trim() === "") {
          errors.set(name, "Required");
        }
      }

      return { ...state, errors };
    }

    function Field({ name, label, error, type = "text" }) {
      const id = useId();
      return (
        <div class="flex items-center gap-2">
          <label for={id}>{label}</label>
          <input id={id} name={name} type={type} />
          <span class="italic">{error}</span>
        </div>
      );
    }

    export default function App() {
      const [state, dispatch] = useReducer(reducer, { errors: new Map() });

      return (
        <form onBlur={dispatch} onSubmit={dispatch} class="flex flex-col items-start gap-4">
          <p class="italic">Fields will individually validate on blur, or every field will validate on submit.</p>
          <fieldset class="flex flex-col gap-2">
            <Field
              name="firstName"
              label="First name"
              error={state.errors.get("firstName")}
            />
            <Field
              name="lastName"
              label="Last name"
              error={state.errors.get("lastName")}
            />
            <Field
              name="email"
              label="Email"
              type="email"
              error={state.errors.get("email")}
            />
          </fieldset>
          <button class="px-3 py-1 bg-blue-300 rounded">Save</button>
        </form>
      );
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
    import { default as App } from "https://gist.githubusercontent.com/RoyalIcing/229db1ce87ea3126c460d232cc1e6b0c/raw/78bdd8c275de4bf38d5430bc0ee6bd6ca7014c84/traffic-lights.jsx";
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

  def show(conn, %{"id" => "downshift-useselect"}) do
    source = ~s"""
    import { useSelect } from 'https://jspm.dev/downshift';

    const items = [
      'apple',
      'pear',
      'orange',
      'grape',
      'banana',
    ];

    const menuStyles = {
      position: 'absolute',
      insetInlineStart: 0,
      insetBlockStart: '100%',
      margin: 0,
      padding: 0,
      listStyle: 'none',
      cursor: 'pointer',
      maxWidth: 'max-content',
      boxShadow: '4px 4px 16px #0006'
    }

    function menuItemStyle(active) {
      return Object.assign({ paddingInline: '1rem', paddingBlock: '0.25rem' }, active && { backgroundColor: '#bde4ff' })
    }

    function DropdownSelect() {
      const {
        isOpen,
        selectedItem,
        getToggleButtonProps,
        getLabelProps,
        getMenuProps,
        highlightedIndex,
        getItemProps,
      } = useSelect({ items })
      return (
        <div style={{ position: 'relative', display: 'flex', gap: '0.5rem' }}>
          <label {...getLabelProps()} style={{ fontWeight: 'bold' }}>Choose an element:</label>
          <div style={{ position: 'relative '}}>
          <button type="button" {...getToggleButtonProps()}>
            {selectedItem || 'Elements'}
          </button>
            <ul {...getMenuProps()} style={menuStyles}>
              {isOpen &&
                items.map((item, index) => (
                  <li
                    style={menuItemStyle(highlightedIndex === index)}
                    key={`${item}${index}`}
                    {...getItemProps({ item, index })}
                  >
                    {item}
                  </li>
                ))}
              </ul>
          </div>
        </div>
      )
    }

    export default function App() {
      return <main>
        <DropdownSelect />
      </main>;
    }
    """

    render_source(conn, source)
  end

  def show(conn, %{"id" => "headlessui-combobox"}) do
    source = ~s"""
    import { Combobox } from 'https://jspm.dev/@headlessui/react';
    import { CheckIcon } from 'https://jspm.dev/@heroicons/react/solid'

    const people = [
      { id: 1, name: 'Durward Reynolds' },
      { id: 2, name: 'Kenton Towne' },
      { id: 3, name: 'Therese Wunsch' },
      { id: 4, name: 'Benedict Kessler' },
      { id: 5, name: 'Katelyn Rohan' },
    ]

    function MyCombobox() {
      const [selectedPerson, setSelectedPerson] = useState(people[0])
      const [query, setQuery] = useState('')

      const filteredPeople =
        query === ''
          ? people
          : people.filter((person) => {
            return person.name.toLowerCase().includes(query.toLowerCase())
          })

      return (
        <Combobox value={selectedPerson} onChange={setSelectedPerson}>
          <Combobox.Input
            onChange={(event) => setQuery(event.target.value)}
            displayValue={(person) => person.name}
          />
          <Combobox.Options>
            {filteredPeople.map((person) => (
              /* Use the `active` state to conditionally style the active option. */
              /* Use the `selected` state to conditionally style the selected option. */
              <Combobox.Option key={person.id} value={person} as={Fragment}>
                {({ active, selected }) => (
                  <li
                    className={`flex items-center gap-1 p-1 ${active ? 'bg-blue-500 text-white' : 'bg-white text-black'
                      }`}
                  >
                    <div className="w-4">
                      {selected && <CheckIcon className="w-4 h-4" />}
                    </div>
                    {person.name}
                  </li>
                )}
              </Combobox.Option>
            ))}
          </Combobox.Options>
        </Combobox>
      )
    }

    export default function App() {
      useEffect(() => {
        // Load Tailwind’s dynamic class generator: https://tailwindcss.com/docs/installation/play-cdn
        const script = Object.assign(document.createElement("script"), {
          src: "https://cdn.tailwindcss.com?plugins=forms,typography,aspect-ratio,line-clamp",
          onload() {
            document.body.classList.toggle("hello") // Trigger Tailwind’s DOM detection
          },
        })
        document.head.appendChild(script)
      }, [])

      return <main>
        <MyCombobox />
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
    import { flavors } from "https://gist.githubusercontent.com/RoyalIcing/d9d2ca7ed6f056632696709a2ae3c413/raw/0234322cf854d52e2f2bd33aa37e8c8b00f9df0a/1.js";
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

  def show(conn, %{"id" => "todo-list-reducer"}) do
    source = ~s"""
    function TodoItem({ item }) {
      const domID = useId();
      const descriptionID = `${domID}-description`;
      const completedID = `${domID}-completed`;

      return <fieldset class="flex items-center gap-3 py-2" data-id={item.id}>
        <input name="completed[]" value={item.id} type="checkbox" checked={item.completed} id={completedID} class="w-5 h-5 text-purple-700 rounded" />
        <label for={descriptionID} class="sr-only">Description</label>
        <input name="description[]" id={descriptionID} type="text" value={item.description} class="flex-1 rounded" />
      </fieldset>
    }

    const initialState = {
      values: {
        focusID: undefined,
        items: [
          {
            id: crypto.randomUUID(),
            description: "File taxes",
            completed: false,
          },
        ],
      },
      errors: {},
    }

    function TodoList() {
      const [{ values, errors }, dispatch] = useReducer(reducer, initialState)

      useLayoutEffect(() => {
        if (!values.focusID) return;

        const el = document.querySelector(`[data-id="${values.focusID}"] input[type=text]`);
        el?.focus();
      }, [values.focusID]);

      return <form className="w-full max-w-[40rem] mx-auto pb-16" onSubmit={(event) => {
        event.preventDefault()
        dispatch(event)
      }}>
        <div onChange={dispatch}>
          {values.items.map((item, index) => (
            <>
              <TodoItem
                key={item.id}
                index={index}
                item={item}
                dispatch={dispatch}
              />
            </>
          ))}
        </div>
        <div className="my-4" />
        <button
          type="button"
          className="py-1 px-3 text-violet-50 bg-violet-800 rounded"
          onClick={dispatch}
          data-action="addItem"
        >Add item</button>
        <pre class="mt-8">{JSON.stringify(values, null, 2)}</pre>
      </form>
    }

    function changed(state, event) {
      const { form } = event.target
      if (!form) {
        return
      }

      const formData = new FormData(form)
      const descriptions = formData.getAll("description[]").map(String)
      const completeds = new Set(formData.getAll("completed[]").map(String))

      for (const [index, item] of state.items.entries()) {
        item.description = descriptions[index]
        item.completed = completeds.has(item.id)
      }
    }

    function clicked(state, event) {
      // event.currentTarget should be the button. The first click it is, but the clicks after are null. Not sure why.

      if (!(event.target instanceof Element)) {
        return
      }
      const button = event.target.closest("button")
      if (!button) {
        return
      }

      const {
        dataset: { action, payload },
      } = button

      if (action === "addItem") {
        const id = crypto.randomUUID()
        state.items.push({
          id,
          description: "",
          completed: false,
        })
        state.focusID = id
      } else if (action === "removeItem") {
        const { id } = JSON.parse(payload) // TODO: use Zod?
        const index = state.items.findIndex((q) => q.id === id)
        state.items.splice(index, 1)
      }
    }

    function reducer(state, event) {
      state = structuredClone(state)

      if (isInputChangeEvent(event)) {
        changed(state.values, event)
      } else if (isClickEvent(event)) {
        clicked(state.values, event)
      } else if (isSubmitEvent(event)) {
        state.errors = validate(state.values)
      }

      return state
    }

    export function isInputChangeEvent(event) {
      return event.type === "change" && event.target instanceof HTMLInputElement
    }

    export function isClickEvent(event) {
      return event.type === "click"
    }

    export function isSubmitEvent(event) {
      return event.type === "submit"
    }

    export default function App() {
      return <TodoList />;
    }
    """

    render_source(conn, source)
  end

  def show(conn, %{"id" => "todo-list-reducer-revisions"}) do
    source = ~s"""
    function TodoItem({ item }) {
      const domID = useId();
      const descriptionID = `${domID}-description`;
      const completedID = `${domID}-completed`;

      return <fieldset class="flex items-center gap-3 py-2 after:content-[attr(data-revision)]" data-id={item.id}>
        <input name="completed[]" value={item.id} type="checkbox" checked={item.completed} id={completedID} class="w-5 h-5 text-purple-700 rounded" />
        <label for={descriptionID} class="sr-only">Description</label>
        <input name="description[]" id={descriptionID} type="text" value={item.description} class="flex-1 rounded" />
      </fieldset>
    }

    const initialState = {
      values: {
        focusID: undefined,
        items: [
          {
            id: crypto.randomUUID(),
            description: "File taxes",
            completed: false,
          },
        ],
      },
      errors: {},
    }

    function TodoList() {
      const [{ values, errors }, dispatch] = useReducer(reducer, initialState)

      useLayoutEffect(() => {
        if (!values.focusID) return;

        const el = document.querySelector(`[data-id="${values.focusID}"] input[type=text]`);
        el?.focus();
      }, [values.focusID]);

      return <form className="w-full max-w-[40rem] mx-auto pb-16" onSubmit={(event) => {
        event.preventDefault()
        dispatch(event)
      }}>
        <div onChange={dispatch}>
          {values.items.map((item, index) => (
            <>
              <TodoItem
                key={item.id}
                index={index}
                item={item}
                dispatch={dispatch}
              />
            </>
          ))}
        </div>
        <div className="my-4" />
        <button
          type="button"
          className="py-1 px-3 text-violet-50 bg-violet-800 rounded"
          onClick={dispatch}
          data-action="addItem"
        >Add item</button>
        <pre class="mt-8">{JSON.stringify(values, null, 2)}</pre>
      </form>;
    }

    function elChanged(el) {
      const newRevision = parseInt(el.dataset.revision ?? "0") + 1;
      el.dataset.revision = newRevision;
      return newRevision;
    }

    function changed(state, event) {
      const input = event.target;
      const { form, dataset } = input;
      if (!form) {
        return;
      }

      const formRevision = elChanged(form);
      dataset.revision = formRevision;
      input.closest('fieldset').dataset.revision = formRevision;

      const formData = new FormData(form);
      const descriptions = formData.getAll("description[]").map(String);
      const completeds = new Set(formData.getAll("completed[]").map(String));

      for (const [index, item] of state.items.entries()) {
        item.description = descriptions[index];
        item.completed = completeds.has(item.id);
      }
    }

    function clicked(state, event) {
      // event.currentTarget should be the button. The first click it is, but the clicks after are null. Not sure why.

      if (!(event.target instanceof Element)) {
        return
      }
      const button = event.target.closest("button")
      if (!button) {
        return
      }

      const {
        dataset: { action, payload },
      } = button

      if (action === "addItem") {
        const id = crypto.randomUUID()
        state.items.push({
          id,
          description: "",
          completed: false,
        })
        state.focusID = id
      } else if (action === "removeItem") {
        const { id } = JSON.parse(payload) // TODO: use Zod?
        const index = state.items.findIndex((q) => q.id === id)
        state.items.splice(index, 1)
      }
    }

    function reducer(state, event) {
      state = structuredClone(state)

      if (isInputChangeEvent(event)) {
        changed(state.values, event)
      } else if (isClickEvent(event)) {
        clicked(state.values, event)
      } else if (isSubmitEvent(event)) {
        state.errors = validate(state.values)
      }

      return state
    }

    export function isInputChangeEvent(event) {
      return event.type === "change" && event.target instanceof HTMLInputElement
    }

    export function isClickEvent(event) {
      return event.type === "click"
    }

    export function isSubmitEvent(event) {
      return event.type === "submit"
    }

    export default function App() {
      return <TodoList />;
    }
    """

    render_source(conn, source)
  end

  def show(conn, _params) do
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
