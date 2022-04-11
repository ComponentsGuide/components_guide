# Understanding React Hooks in a Concurrent World

- `useId`: generate a unique value consistently on the server & browser side.
- `useMemo` & `useCallback`: recalculate output when inputs change @ render time.
- `useDeferredValue`: recalculate output to be input when any urgent updates have been committed.
- `useState`: recalculate output when called @ render time.
- `useReducer`: recalculate output when called @ any time.
- `useEffect`: executed by React when inputs change @ commit time.
- `useContext`: state external to this component provided by another component further up the tree.
- `useRef`: mutable reference that can be changed @ any time.
- [Hooks Reference](https://reactjs.org/docs/hooks-reference.html)

## Parallel-Universe-Safe

### `useMemo`, `useState`, `useReducer`



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
