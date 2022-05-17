# Zero Hook Dependencies
# Opinionated React Hooks

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

## Don’t `useRef` for state
