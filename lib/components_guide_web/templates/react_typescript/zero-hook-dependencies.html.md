# The pain of useEffect’s dependencies

While React is great for diffing elements that get shown to the user, it shouldn’t be used for reliably diffing values that produces side effects.

Or — `useEffect` dependencies considered painful.

## The problem

It can seem like hook dependencies are similar to passed props in React: you simply declare what you want to use, and React works out what has changed and skips work if there are no changes.

```js
function App({ title }) {
  return <html>
    <head>
      <title>{title}</title>
    </head>
  </html>;
}
```

```js
function App({ title }) {
  useEffect(() => {
    window.document.title = title;
  }, [title]);

  return null;
}
```

However, there’s one big difference. React’s changes to the DOM are inert: if React accidentally creates a DOM element with the same values that were already rendered, there’s no behaviour difference. (Excepting scenarios where we care about the identity of the element, like focusing). It’s just slightly inefficient.

```js
const root = createRoot(document.body);
// We render once with one key:
root.render(<button key={11}>Some button</button>);
// and then again with another, which means we’ll destroy the DOM element and create a new one!
// But… because the DOM output is the same, it’s actually safe. Just a little inefficient.
root.render(<button key={99}>Some button</button>);
```

But if React calls your effect more times than you expected, then that’s changing behaviour.

```js
useEffect(() => {
  // Are we actually guaranteed that page_view will only be sent when `myAnalytics` or `viewedItem` changes?
  // Do we actually care if `myAnalytics` changes?
  // What about <StrictMode>?
  myAnalytics.send("page_view");
}, [myAnalytics, viewedItem]);
```

This why the StrictMode double firing effects has been so disruptive — the actual behavior is different from what the developer intended. But I believe the dependencies to React’s hooks should be treated as an optimization, not as a guarantee of specific behavior.

What we have to do is make side effects as safe as setting an attribute, and we can do that with a helpful property called idempotency.

## Don’t pass dependencies to `useEffect`

Here’s my proposed solution to dependencies — get rid of them! That way we aren’t relying any guarantees from React when your effect is called. Instead that responsibility will lie with you. In general, using React for declaring the *what* and not using for the *when* is a good way to have an easier time with React. React and its scheduler is a black box, and we should treat it as such.

We’ll take code like:

```js
useEffect(() => {
  performSearch(searchQuery);
}, [searchQuery]);
```

And turn it into this:

```js
useEffect(() => {
  // Use an idempotent operation which can be requested multiple times safely.
  performSearch(searchQuery);
});
```

## If your state is in React

```js
function SearchForm() {
  const [searchQuery, updateQuery] = useState("");

  useEffect(() => {
    // Use an idempotent operation which can be requested multiple times safely.
    performSearch(searchQuery);
  });

  return <form role="search">
    <input type="search" onChange={(event) => {
      updateQuery(event.target.value);
    }}>
  </form>;
}
```

### Using an external Map and `useId`

```js
const searchIDToQueries = new Map();

function SearchForm() {
  const searchID = useId();
  const [searchQuery, updateQuery] = useState("");
  const [searchResult, updateResult] = useState(null);

  if (searchResult instanceof Error) {
    throw searchResult;
  }

  useEffect(() => {
    if (searchIDToQueries.get(searchID) === searchQuery) {
      return;
    }

    searchIDToQueries.set(searchID, searchQuery);

    performSearch(searchQuery)
      .then(updateResult)
      .catch(updateResult);
  });

  return <form role="search">
    <input type="search" onChange={event => {
      updateQuery(event.target.value);
    }} />
    <output>
      <ul>{searchResults.map(result =>
        <li key={result.key}>{result.title}</li>
      )}</ul>
    </output>
  </form>;
}
```

```js
const searchQueriesToPromises = new Map();

function SearchForm() {
  const [searchQuery, updateQuery] = useState("");
  const [searchResults, updateResult] = useState(null);

  useEffect(() => {
    if (searchQueriesToPromises.has(searchQuery)) {
      return;
    }

    searchQueriesToPromises.set(searchQuery, performSearch(searchQuery));
  });

  return <form role="search">
    <input type="search" onChange={event => {
      updateQuery(event.target.value);
    }} />
    <output>
      <ul>{searchResults.map(result =>
        <li key={result.key}>{result.title}</li>
      )}</ul>
    </output>
  </form>;
}
```

Summary:
- Change your React effects [to be idempotent](/robust-javascript/idempotent-javascript-operations), which means they can be called multiple times safely.
- Adding a dependency means both 1. I want to read this value 2. I want to run *when* this value changes. It’s conflating two responsibilities. Removing the dependencies means you can read *any* value, and the when is taken care of with idempotency.

## Example: autosave

Before:

- `useEffect` has 3 dependencies.
- React will diff dependencies to see what has changed.
- _May_ run after committing if any of the 3 dependencies change.

```js
const fetcher = useFetcher();
const queryToSave = useDebouncedMemo(() => query.clock === 0 ? null : query, 1000, [query]);
useEffect(() => {
  if (queryToSave === null) {
    return;
  }

  fetcher.submit(queryToSave.searchParams, { method: "post" })
}, [fetcher.submit, projectID, queryToSave]);
```

After:

- `useEffect` has zero dependencies.
- Runs after committing.
- We do our own check to see what has changed, and whether we should bail or procede.

```js
const fetcherLastValues = new WeakMap();

const fetcher = useFetcher();
useEffect(() => {
  if (queryToSave === null) {
    return;
  }

  const key = queryToSave.searchParams.toString();
  if (key === fetcherLastValues.get(fetcher)) {
    return;
  }
  fetcherLastValues.set(fetcher, key);

  fetcher.submit(queryToSave.searchParams, { method: "post" })
});
```

## Bonus: what if it errors?

## Bonus: aborting earlier requests



## Don’t `useRef` for state
