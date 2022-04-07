# Understanding React Hooks in a Concurrent World

- `useId`
- `useMemo` & `useCallback`
- `useState` & `useReducer`
- `useContext`
- `useDeferredValue`
- `useRef`
- `useEffect`
- [Hooks Reference](https://reactjs.org/docs/hooks-reference.html)

## Parallel-Universe-Safe

### `useMemo`, `useState`, `useReducer`

- `useMemo` & `useCallback`: recalculate output when inputs change. (only at render time)
- `useDeferredValue`: recalculate output to be input when any urgent updates have been committed.
- `useState`: recalculate output when called. (at any time)
- `useReducer`: recalculate output when called. (at any time)
- `useEffect`: call when inputs change. (only at commit time)
- `useContext`: state external to this component provided by another component further up the tree.

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
