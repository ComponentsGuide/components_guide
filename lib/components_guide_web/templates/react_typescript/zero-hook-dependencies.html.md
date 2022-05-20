# The pain of useEffect’s dependencies

`useEffect` dependencies considered painful.

## Don’t pass dependencies to `useEffect`

Before:

```js
useEffect(() => {
  performSearch(searchQuery);
}, [searchQuery]);
```

After:

```js
useEffect(() => {
  // Use an idempotent operation which can be requested multiple times safely.
  performSearch(searchQuery);
});
```

Summary:
- Change your React effects [to be idempotent](/robust-javascript/idempotent-javascript-operations), which means they can be called as multiple times safely.
- Adding a dependency means both 1. I want to read this value 2. I want to run *when* this value changes. It’s conflating two responsibilities. Removing the dependencies means you can read *any* value, and the when is taken care of with idempotency.

It can seem like hook dependencies are similar to passed props in React: you simply declare what you want to use, and React works out what has changed and skips work if there are no changes. However, there’s one huge difference. React’s changes to the DOM are inert: if React accidentally set a DOM element’s attribute to the same value it already has, there’s no behaviour difference. It’s just slightly inefficient. But if React calls your effect more times than you expected, then that’s changing behaviour. (That’s why the StrictMode double firing effects has been so disruptive) What we have to do is make it as safe as setting an attribute, and we can do that with idempotency.

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
