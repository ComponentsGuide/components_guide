# Understanding React Hooks in a Concurrent World

- `useId`: generate a unique value consistently on the server & browser side, usually for `id` attributes.
- `useState` & `useReducer`: holds data that can be changed @ any time.
- `useSyncExternalStore`: subscribes to an external source of data.
- `useMemo` & `useCallback`: recalculate output when inputs change @ render time.
- `useContext`: subscribes to data provided by another component further up the tree.
- `useDeferredValue`: forks a piece of state, rendering in the background until suspended components have loaded, rendering previous state in the meanwhile.
- `useEffect`: executed by React when inputs change @ commit time.
- `useRef`: holds unsafe data that can be changed @ any time.
- [View Official Hooks Reference](https://reactjs.org/docs/hooks-reference.html)

## Parallel-Universe-Safe

### `useMemo`, `useState`, `useReducer`

Each of these hooks hold state.

### `useRef` + `useEffect`

```js
const instRef = useRef(null);
let inst;
// Lazily initialize the ref the first time.
if (instRef.current === null) {
  inst = {
    value: null,
  };
  instRef.current = inst;
} else {
  inst = instRef.current;
}

…

// Update the ref once value has been committed.
useEffect(() => {
  inst.value = value;
}, [value]);
```

## Parallel-Universe-Unsafe

### `useRef`
